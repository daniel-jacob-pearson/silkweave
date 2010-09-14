require 'rubygems'
begin
  require 'stitch'
rescue LoadError
  $LOAD_PATH.push File.expand_path('../lib', __FILE__) # :development:
  require 'stitch'
end

run Stitch.app(File.expand_path('../example_site', __FILE__))

# vim: ft=ruby
