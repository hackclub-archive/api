class V1::Streak::PipelinesController < ApplicationController
  def index
    render json: ::Streak::Pipeline.all, status: 200
  end

  def sync
    # Run the whole sync in a transaction just in case something goes wrong.
    ::Streak::Pipeline.transaction do
      # Our source data
      stored_pipelines = ::Streak::Pipeline.all
      stored_fields = ::Streak::Field.all
      remote_pipelines = ::StreakClient::Pipeline.all

      # Figure out which local pipelines and fields need to be deleted by
      # checking to see if we have any Streak keys that aren't present in the
      # API response.

      # Find pipelines to delete
      remote_pipeline_keys = remote_pipelines.map { |p| p[:key] }

      stored_pipelines_to_delete = stored_pipelines.select do |p|
        !remote_pipeline_keys.include?(p.streak_key)
      end

      # Find fields to delete
      remote_field_keys = remote_pipelines.reduce([]) do |keys, p|
        p[:fields].each do |field|
          keys << { pipeline_key: p[:key], streak_key: field[:key] }
        end

        keys
      end

      stored_fields_to_delete = stored_fields.select do |f|
        !remote_field_keys.include?({
          pipeline_key: f.pipeline.streak_key,
          # We store field keys as integers, Streak stores them as strings
          streak_key: f.streak_key.to_s
        })
      end

      # Delete the identified fields
      stored_fields_to_delete.each do |f|
        f.destroy
      end

      # Delete the identified pipelines
      stored_pipelines_to_delete.each do |p|
        p.destroy
      end

      # Update (or create, if necessary) all of the pipelines from the API
      remote_pipelines.each do |remote_pipeline|
        pipeline = ::Streak::Pipeline.find_or_initialize_by(
          streak_key: remote_pipeline[:key]
        )

        pipeline.update_attributes!(name: remote_pipeline[:name])

        remote_pipeline[:fields].each do |remote_field|
          field = ::Streak::Field.find_or_initialize_by(
            streak_key: remote_field[:key],
            pipeline: pipeline
          )

          field.update_attributes!(
            name: remote_field[:name],
            field_type: remote_field[:type]
          )
        end
      end
    end

    index
  end
end
