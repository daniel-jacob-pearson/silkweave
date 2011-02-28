# encoding: UTF-8

module Silkweave
  module Middleware
    # This Rack middleware is used instead of +ActionDispatch::Head+ because it
    # has the annoying habit of destructively changing +env["REQUEST_METHOD"]+
    # from "HEAD" to "GET", making HEAD requests undetectable in the logs.
    class Head
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
        if env["REQUEST_METHOD"] == "HEAD"
          omit_body = true
        end
        status, headers, body = @app.call(env)
        if omit_body
          [status, headers, []]
        else
          [status, headers, body]
        end
      end
    end
  end
end
