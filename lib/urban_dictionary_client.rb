module UrbanDictionaryClient
  class << self
    BASE_URL = 'https://api.urbandictionary.com/v0/define'.freeze

    def define(query)
      headers = {
        params: {
          term: query
        }
      }

      resp = RestClient.get(BASE_URL, headers)
      data = JSON.parse(resp, symbolize_names: true)
      data[:result_type] == "no_results" ? nil : data[:list].first[:definition]
    end
  end
end
