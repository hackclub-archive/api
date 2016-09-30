require 'rails_helper'

RSpec.describe "V1::Streak::Pipelines", type: :request do
  describe "GET /v1/streak/pipelines" do
    it "returns an empty array when no pipelines exist" do
      get "/v1/streak/pipelines"

      expect(response).to have_http_status(200)
      expect(response.content_type).to eq("application/json")
      expect(json).to eq([])
    end

    context "when multiple pipelines exist" do
      before do
        5.times { create(:streak_pipeline) }
      end

      it "returns the correct number of pipelines" do
        get "/v1/streak/pipelines"

        expect(response).to have_http_status(200)
        expect(response.content_type).to eq("application/json")
        expect(json.length).to eq(5)
      end

      context "where the first pipeline doesn't have any fields" do
        it "has an empty array for fields" do
          get "/v1/streak/pipelines"

          expect(response).to have_http_status(200)
          expect(response.content_type).to eq("application/json")
          expect(json.first["fields"]).to eq([])
        end
      end

      context "where the first pipeline has fields" do
        before do
          5.times { Streak::Pipeline.first.fields.create(attributes_for(:streak_field)) }
        end

        it "returns the correct number of fields" do
          get "/v1/streak/pipelines"

          expect(response).to have_http_status(200)
          expect(response.content_type).to eq("application/json")
          expect(json.first["fields"].length).to eq(5)
        end
      end
    end
  end

  describe "POST /v1/streak/pipelines/sync" do
    let(:api_pipelines) do
      def gen_api_pipeline
        attrs = attributes_for(:streak_pipeline)
        fields = rand(1..5).times.collect { attributes_for(:streak_field) }

        {
          key: attrs[:streak_key],
          name: attrs[:name],
          fields: fields.map { |f|
            {
              name: f[:name],
              # Need to convert to string for the faked response because we
              # store this as an integer internally
              key: f[:streak_key].to_s,
              type: f[:field_type]
            }
          }
        }
      end

      5.times.collect { gen_api_pipeline }
    end

    let(:total_field_count) do
      api_pipelines
        .map { |p| p[:fields].length }
        .reduce(:+)
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

      it "syncs all pipeline fields" do
        expect {
          post "/v1/streak/pipelines/sync"
        }.to change{Streak::Field.count}.from(0).to(total_field_count)
      end

      it "returns a list of all of the stored pipelines" do
        post "/v1/streak/pipelines/sync"

        expect(response).to have_http_status(200)
        expect(response.content_type).to eq("application/json")
        expect(json.length).to eq(5)
      end

      it "includes fields in the returned pipeline list" do
        post "/v1/streak/pipelines/sync"

        expect(response).to have_http_status(200)
        expect(response.content_type).to eq("application/json")

        json.each_with_index do |pipeline, i|
          resp_field_count = pipeline["fields"].length
          api_field_count = api_pipelines[i][:fields].length

          expect(resp_field_count).to eq(api_field_count)
        end
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

        it "should update the outdated pipeline's name" do
          expect {
            post "/v1/streak/pipelines/sync"
          }.to change{outdated_pipeline.reload.name}.to(api_pipelines.last[:name])
        end

        it "should create the 4 other pipelines" do
          expect {
            post "/v1/streak/pipelines/sync"
          }.to change{Streak::Pipeline.count}.by(4)
        end

        context "that have fields that need to be updated" do
          let!(:outdated_field) {
            api_field = api_pipelines.last[:fields].last

            Streak::Field.create(
              pipeline: outdated_pipeline,
              streak_key: api_field[:key],
              name: "#{api_field[:name]} (OUTDATED)",
              field_type: "#{api_field[:type]} (OUTDATED)"
            )
          }

          it "should update the outdated's field's name" do
            expect {
              post "/v1/streak/pipelines/sync"
            }.to change {
              outdated_field.reload.name
            }.to(api_pipelines.last[:fields].last[:name])
          end

          it "should update the outdated's field's type" do
            expect {
              post "/v1/streak/pipelines/sync"
            }.to change {
              outdated_field.reload.field_type
            }.to(api_pipelines.last[:fields].last[:type])
          end
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

      context "that have fields that need to be deleted" do
        let!(:pipeline) {
          Streak::Pipeline.create(
            streak_key: api_pipelines.last[:key],
            name: api_pipelines.last[:name]
          )
        }

        let!(:outdated_field) do
          pipeline.fields.create(attributes_for(:streak_field))
        end

        it "should delete the old field" do
          post "/v1/streak/pipelines/sync"

          expect(
            Streak::Field.find_by(
            pipeline: pipeline,
            streak_key: outdated_field.streak_key
          )).to be(nil)
        end
      end
    end
  end
end
