# Resources
require 'streak_client/pipeline'
require 'streak_client/box'

# Errors
require 'common_client/errors/api_error'
require 'common_client/errors/authentication_error'

# API client to Streak
module StreakClient
  @api_base = 'https://www.streak.com/api'

  class << self
    attr_accessor :api_key, :api_base

    def api_url(url = '')
      @api_base + url
    end

    # rubocop:disable Metrics/MethodLength
    def request(method, path, params = {}, headers = {}, encoding = :auto)
      payload = nil

      raise AuthenticationError, 'No API key provided' unless @api_key

      headers['Authorization'] = construct_http_auth_header(@api_key, '')

      params = transform_params(params)

      encoding = auto_detect_encoding encoding if encoding == :auto

      case encoding
      when :url_encoding
        headers[:params] = params
      when :json_encoding
        headers['Content-Type'] = 'application/json'
        payload = params.to_json
      end

      resp = RestClient::Request.execute(method: method, url: api_url(path),
                                         headers: headers, payload: payload)

      parse(resp)
    end
    # rubocop:enable Metrics/MethodLength

    private

    def auto_detect_encoding(method)
      case method
      when :post
        :json_encoding
      when :put, :get
        :url_encoding
      end
    end

    def construct_http_auth_header(username, password)
      "Basic #{Base64.strict_encode64(username + ':' + password)}"
    end

    def transform_params(params)
      params
        .clone
        .deep_transform_keys { |k| k.to_s.camelize(:lower) }
    end

    # rubocop:disable Metrics/MethodLength
    def parse(response)
      parsed = JSON.parse(response, symbolize_names: true)

      snake_case_transform = lambda do |hash|
        hash
          .deep_transform_keys(&:to_s)
          .deep_transform_keys(&:underscore)
          .deep_transform_keys(&:to_sym)
      end

      if parsed.class == Array
        parsed.map(&snake_case_transform)
      else
        snake_case_transform.call(parsed)
      end
    end
    # rubocop:enable Metrics/MethodLength
  end
end
