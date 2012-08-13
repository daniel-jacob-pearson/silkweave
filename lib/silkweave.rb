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
# [Author]    Daniel Pearson <daniel@nanoo.org>
#
# [License]   CC0 <http://creativecommons.org/publicdomain/zero/1.0/>
#
# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide. This software is distributed without any warranty.
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
  autoload :Version

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
  module SilkweavePatch
    def initialize path
      if path.respond_to? :to_str
        path = path.to_str
      elsif path.respond_to? :to_path
        path = path.to_path
      end
      super path
    end
  end
  include SilkweavePatch
end
