# encoding: UTF-8

module Silkweave
  # This module contains classes that implement Rack middleware for internal
  # use by Silkweave.
  module Middleware
    extend ActiveSupport::Autoload

    autoload :AddSlash
    autoload :Head
  end
end
