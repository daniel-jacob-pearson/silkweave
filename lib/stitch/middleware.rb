module Stitch
  # This module contains classes that implement Rack middleware for internal
  # use by Stitch.
  module Middlware
    extend ActiveSupport::Autoload

    autoload :Head
    autoload :Length
  end
end
