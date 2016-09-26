class V1::Streak::PipelinesController < ApplicationController
  def index
    render json: ::Streak::Pipeline.all, status: 200
  end

  def sync
    # Run the whole sync in a transaction just in case something goes wrong.
    ::Streak::Pipeline.transaction do
      # Our source data
      stored_pipelines = ::Streak::Pipeline.all
      remote_pipelines = ::StreakClient::Pipeline.all

      # Figure out which local pipelines needs to be deleted by checking to see if
      # we have any Streak keys that aren't present in the API response.
      remote_pipeline_keys = remote_pipelines.map { |p| p[:key] }

      stored_pipelines_to_delete = stored_pipelines.select do |p|
        !remote_pipeline_keys.include?(p.streak_key)
      end

      # Delete the identified pipelines
      stored_pipelines_to_delete.each do |p|
        p.destroy
      end

      # Update (or create, if necessary) all of the pipelines from the API
      remote_pipelines.each do |p|
        ::Streak::Pipeline
          .find_or_initialize_by(streak_key: p[:key])
          .update_attributes!(name: p[:name])
      end
    end

    index
  end
end
