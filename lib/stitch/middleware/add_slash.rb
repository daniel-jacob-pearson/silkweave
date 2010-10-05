module Stitch
  module Middleware
    # This middleware ensures that the PATH_INFO of requests for directories
    # ends with a slash. It does so by sending a 301 redirection response when
    # the slash is missing. This ensures that relative URL references within
    # the final response body will resolve correctly.
    class AddSlash
      # Initializes the middleware.
      #
      # @param [#call] app The Rack application to wrap with this middleware.
      #
      # @param [#to_str] root The directory from which requested files are
      #   served.
      def initialize(app, root)
        @app, @root = app, root
      end

      # As required by the Rack specification.
      #
      # @param [Hash] env An environment as defined by the Rack spec.
      #
      # @return [(#to_i, {String => String}, #each)] A Rack-conformant response.
      def call(env)
        path = Rack::Utils.unescape(env["PATH_INFO"])
        if path[-1..-1] != '/' and File.directory?(File.join(@root, path))
          note = "<a href='#{path}/'>#{path}/</a>"
          [301, {
            'Location' => path + '/',
            'Content-Type' => 'text/html',
            'Content-Length' => note.length.to_s
          }, [note]]
        else
          @app.call(env)
        end
      end
    end
  end
end
