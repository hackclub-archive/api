module StreakClient
  module Pipeline
    def self.all
      Streak.request(:get, "/v1/pipelines")
    end

    def self.find(key)
      Streak.request(:get, "/v1/pipelines/#{key}")
    end
  end
end
