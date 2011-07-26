require 'rubygems'
require 'silkweave'

run Silkweave::Site.new File.expand_path('../pages', __FILE__)
