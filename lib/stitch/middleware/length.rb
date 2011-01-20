# encoding: UTF-8

module Stitch
  module Middleware
    # This Rack middleware is used instead of +Rack::ContentLength+ because it
    # ignores response bodies that are instances of +Rack::Response+ (as is
    # true for responses produced by +ActionController+).  Beware that this
    # middleware assumes that iterating over any instance of +Rack::Response+
    # is idempotent.
    class Length
      include Rack::Utils

      # Initializes the middleware.
      #
      # @param [#call] app The Rack application to wrap with this middleware.
      def initialize(app)
        @app = app
      end

      # As required by the Rack specification.
      #
      # @param [Hash] env An environment as defined by the Rack spec.
      #
      # @return [(#to_i, {String => String}, #each)] A Rack-conformant response.
      def call(env)
        status, headers, body = @app.call(env)
        headers = HeaderHash.new(headers)

        if !STATUS_WITH_NO_ENTITY_BODY.include?(status.to_i) &&
           !headers['Content-Length'] &&
           !headers['Transfer-Encoding'] &&
           (body.respond_to?(:to_ary) ||
            body.respond_to?(:to_str) ||
            body.is_a?(Rack::Response))

          if body.respond_to?(:to_str) # rack 0.4 compatibility
            body = [body]
          elsif body.respond_to?(:to_ary)
            body = body.to_ary
          else
            body.extend(Enumerable)
          end
          length = body.inject(0) { |len, part| len + bytesize(part) }
          headers['Content-Length'] = length.to_s
        end

        [status, headers, body]
      end
    end
  end
end
