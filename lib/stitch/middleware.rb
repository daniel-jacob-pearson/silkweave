# encoding: UTF-8

module Stitch
  # This module contains classes that implement Rack middleware for internal
  # use by Stitch.
  module Middleware
    extend ActiveSupport::Autoload

    autoload :AddSlash
    autoload :Head
    autoload :Length
  end
end
