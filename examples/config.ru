$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rubygems'
require 'silkweave'

run Silkweave::Site.new File.expand_path('../site-root', __FILE__)

# vim: ft=ruby
