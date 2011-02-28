#!/usr/bin/env ruby

require 'rubygems'
require 'rack'
require 'silkweave'

Rack::Handler::CGI.run Silkweave::Site.new(File.expand_path('..', __FILE__))
