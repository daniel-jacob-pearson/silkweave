# encoding: UTF-8
#
# Silkweave - A framework to make web sites out of file trees with templates.
#
# Written in 2010-2012 by Daniel Jacob Pearson <daniel@nanoo.org>.
#
# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide. This software is distributed without any warranty.
#
# You should have received a copy of the CC0 Public Domain Dedication along with
# this software. If not, see http://creativecommons.org/publicdomain/zero/1.0/.

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
