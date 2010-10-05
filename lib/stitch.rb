require 'pathname'
require 'rack'
require 'action_controller'
require 'action_dispatch'
require 'haml'
require 'haml/template'

# Stitch is a framework for creating a Web site out of a file tree with the
# help of templates.  
#
# Author::    Daniel Pearson (mailto:daniel@nanoo.org)
# Copyright:: Copyright (c) 2010 Daniel Pearson
# License::   ISC, as noted below
#
#   'Permission to use, copy, modify, and/or distribute this software for any
#   purpose with or without fee is hereby granted, provided that the above
#   copyright notice and this permission notice appear in all copies.
#
#   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
#   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
#   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
#   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
#   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
#   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.'
#
# == Deployment
#
# Stitch is deployed with Rack (see http://rack.rubyforge.org/). A Rack app
# object appropriate for deploying Stitch with a Rack-capable Web server can be
# produced with +Stitch.app+.
#
# == URL Paths Versus Filesystem Paths
#
# In various parts of the documentation for +Stitch+, two types of file
# pathnames are distinguished with the terms "URL path" and "filesystem path".
# "URL paths" are path names used to locate resources on a Web site. They are
# the sort of path that a Web browser requests from a Web server. "Filesystem
# paths" are path names that locate objects on the Web server's filesystem.
module Stitch
  extend ActiveSupport::Autoload

  autoload :Utils
  autoload :Needle
  autoload :AbstractPage
  autoload :PageTypes
  autoload :Middleware

  # Returns a Rack (end-point) app for starting up Stitch. Use it as the
  # argument to +run+ in a rackup configuration file (+config.ru+), or
  # otherwise integrate it into a Rack-capable Web server. 
  #
  # @example In a config.ru file:
  #   run Stitch.app('/var/www')
  #
  # @example Running as a CGI script:
  #   Rack::Handler::CGI.run Stitch.app('/home/nancy/public_html')
  #
  # @param [Pathname, #to_str, #to_path] root
  #
  #   The directory that will serve as the Web site's root.
  #
  #   All paths requested from the Web site will be resolved into paths within
  #   the given root directory. It must be set to an absolute pathname. If you
  #   assign a relative pathname, then it will be coerced into an absolute
  #   pathname by prefixing "/", which may not produce the result you desire,
  #   so you're better off only assigning pathnames that are already absolute.
  def self.app(root)
    Needle.site_root = root
    Needle.middleware.clear
    Needle.use Middleware::Head
    Needle.use Middleware::AddSlash, root
    Needle.use Middleware::Length
    Needle.use ActionDispatch::Static, root
    Needle.action :sew
  end

  # The common ancestor for all exceptions that trigger HTTP error responses.
  # You shouldn't raise this directly. All subclasses of this should be named
  # after the HTTP status code that is being triggered.
  class HTTPError < StandardError; end

  # Raising this indicates that a requested resource could not be found and
  # therefore triggers the sending of a 404 HTTP response to the client. The
  # +message+ attribute of this exception should be set to the path of the
  # requested resource.
  class NotFound < HTTPError; end

  # Raising this indicates that the server refuses to provide the requested
  # resource and therefore triggers the sending of a 403 HTTP response to the
  # client. The +message+ attribute of this exception should be set to the path
  # of the requested resource.
  class Forbidden < HTTPError; end

  # Raising this indicates that a request couldn't be fulfilled because the
  # server is somehow misconfigured and requires repair to fill the request. It
  # triggers the sending of a 500 HTTP response to the client. The +message+
  # attribute of this exception should be set to a description of the problem
  # that points toward how to fix it.
  class InternalServerError < HTTPError; end
end

# Load all page type classes.
Dir[File.expand_path('../stitch/page_types/*.rb',__FILE__)].each do |page_type|
  require page_type
end
