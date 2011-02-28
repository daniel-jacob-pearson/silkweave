# encoding: UTF-8

require 'pathname'
require 'rack'
require 'action_controller'
require 'action_dispatch'
require 'haml'
require 'haml/template'

# Silkweave is a framework for creating a Web site out of a file tree with the
# help of templates.  
#
# [Author]    Daniel Pearson (mailto:daniel@nanoo.org)
#
# [Copyright] Copyright (c) 2010 Daniel Pearson
#
# [License]   ISC, as stated below
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.
#
# == Deployment
# Silkweave is deployed with Rack (see http://rack.rubyforge.org/). Instances of
# the +Silkweave::Site+ class are Rack app objects appropriate for deploying with
# a Rack-capable Web server.
#
# == URL Paths Versus Filesystem Paths
# In various parts of the documentation for Silkweave, two types of file pathnames
# are distinguished with the terms "URL path" and "filesystem path". "URL
# paths" are path names used to locate resources on a Web site. They are the
# sort of path that a Web browser requests from a Web server. "Filesystem
# paths" are path names that locate objects on the Web server's filesystem.
module Silkweave
  extend ActiveSupport::Autoload

  autoload :Arachne
  autoload :AbstractPage
  autoload :PageTypes
  autoload :Middleware
  autoload :Site

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

# Load all page type classes that are included with the Silkweave distribution.
Dir[File.expand_path('../silkweave/page_types/*.rb',__FILE__)].each do |page_type|
  require page_type
end

#--
# I'm monkey-patching Pathname because I don't like its split personality
# regarding #to_str and #to_path. There's no reason not to support both at the
# same time, all the time, regardless of Ruby version.
#++
class Pathname
  alias_method :to_str, :to_s
  alias_method :to_path, :to_s
  old_init = self.instance_method :initialize
  define_method :initialize do |path|
    if path.respond_to? :to_str
      path = path.__send__ :to_str
    elsif path.respond_to? :to_path
      path = path.__send__ :to_path
    end
    old_init.bind(self).call(path)
  end
end
