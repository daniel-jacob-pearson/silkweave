module Stitch
  # @private
  #
  # This Rack middleware is used instead of +ActionDispatch::Head+ and
  # +Rack::ContentLength+ because of their shortcomings. (It darns away their
  # worn and holey spots.) +Rack::ContentLength+ ignores response bodies that
  # are instances of +Rack::Response+ (as is true for responses produced by
  # +ActionController+). And if +ActionDispatch::Head+ is applied before the
  # Content-Length header is explicitly set, Content-Length will eventually be
  # computed as zero, which is just plain wrong if a GET request to the same
  # URL would result in a response with a non-zero Content-Length header.
  # +ActionDispatch::Head+ also has the annoying habit of destructively
  # changing +env["REQUEST_METHOD"]+ from "HEAD" to "GET", making HEAD requests
  # undetectable in the logs.
  #
  # The caveat to this middleware is that it assumes that iterating over any
  # instance of +Rack::Response+ is idempotent.
  class Darning
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
      if env["REQUEST_METHOD"] == "HEAD"
        omit_body = true
      end
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

      if omit_body
        [status, headers, []]
      else
        [status, headers, body]
      end
    end
  end
end
