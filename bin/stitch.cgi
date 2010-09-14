#!/usr/bin/env ruby

require 'rubygems'
require 'rack'
require 'stitch'

Rack::Handler::CGI.run Stitch.app(File.expand_path('..', __FILE__))
