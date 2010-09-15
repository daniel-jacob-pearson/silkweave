$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'rubygems'
require 'stitch'

#begin
#  require 'stitch'
#rescue LoadError
#  $LOAD_PATH.push File.expand_path('../lib', __FILE__) # :development:
#  require 'stitch'
#end

run Stitch.app(File.expand_path('../example_site', __FILE__))

# vim: ft=ruby
