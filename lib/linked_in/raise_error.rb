require 'faraday'

module LinkedIn
  class RaiseError < Faraday::Response::RaiseError
    def on_complete(response)
      case response.status.to_i
      when 400
        fail(LinkedIn::ArgumentError, MultiJson.load(response.body)['message'] || LinkedIn::ErrorMessages.argument_missing) if response.body =~ /is missing/i
        fail(LinkedIn::InvalidRequest, MultiJson.load(response.body)['message'] || LinkedIn::ErrorMessages.arguments_malformed)
      when 401
        response_content = MultiJson.load(response.body)
        fail LinkedIn::UnauthorizedError, "#{response_content['message']} (error_code: #{response_content['errorCode']}, request_id: #{response_content['requestId']})"
      when 403
        fail LinkedIn::ThrottleError if response.body =~ /throttle/i
        fail LinkedIn::PermissionsError, MultiJson.load(response.body)['message'] || LinkedIn::ErrorMessages.not_permitted
      else
        super
      end
    end
  end
end

Faraday::Response.register_middleware :linkedin_raise_error => LinkedIn::RaiseError
