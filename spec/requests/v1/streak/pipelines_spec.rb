require 'rails_helper'

RSpec.describe "V1::Streak::Pipelines", type: :request do
  describe "GET /v1/streak/pipelines" do
    it "returns an empty array when no pipelines exist" do
      get "/v1/streak/pipelines"

      expect(response).to have_http_status(200)
      expect(response.content_type).to eq("application/json")
      expect(json).to eq([])
    end

    context "when multiple clubs exist" do
      before do
        5.times { create(:streak_pipeline) }
      end

      it "returns the correct number of pipelines" do
        get "/v1/streak/pipelines"

        expect(response).to have_http_status(200)
        expect(response.content_type).to eq("application/json")
        expect(json.length).to eq(5)
      end
    end
  end

  describe "POST /v1/streak/pipelines/sync" do
    let(:api_pipelines) do
      def gen_api_pipeline
        attrs = build(:streak_pipeline)

        {
          key: attrs[:streak_key],
          name: attrs[:name]
        }
      end

      5.times.collect { gen_api_pipeline }
    end

    before do
      stub_request(:get, "https://www.streak.com/api/v1/pipelines")
        .to_return(:status => 200, :body => api_pipelines.to_json)
    end

    context "no stored pipelines" do
      it "syncs all of the pipelines" do
        expect {
          post "/v1/streak/pipelines/sync"
        }.to change{Streak::Pipeline.count}.from(0).to(5)
      end

      it "returns a list of all of the stored pipelines" do
        post "/v1/streak/pipelines/sync"

        expect(response).to have_http_status(200)
        expect(response.content_type).to eq("application/json")
        expect(json.length).to eq(5)
      end
    end

    context "with stored pipelines" do
      context "that need to be updated" do
        let!(:outdated_pipeline) {
          Streak::Pipeline.create(
            streak_key: api_pipelines.last[:key],
            name: "#{api_pipelines.last[:name]} (OUTDATED)"
          )
        }

        it "should update the outdated pipeline's field" do
          expect{
            post "/v1/streak/pipelines/sync"
          }.to change{outdated_pipeline.reload.name}.to(api_pipelines.last[:name])
        end

        it "should create the 4 other pipelines" do
          expect{
            post "/v1/streak/pipelines/sync"
          }.to change{Streak::Pipeline.count}.by(4)
        end
      end

      context "that need to be deleted" do
        let!(:outdated_pipeline) {
          create(:streak_pipeline)
        }

        it "should delete the old pipeline" do
          post "/v1/streak/pipelines/sync"

          expect(Streak::Pipeline.find_by(id: outdated_pipeline.id)).to be(nil)
        end
      end
    end
  end
end
