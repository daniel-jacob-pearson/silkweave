# encoding: UTF-8

require 'stitch/page_types/base'

module Stitch
  module PageTypes
    # A plain page has a +@title+ and a chunk of +@content+. The title is a
    # short description of the page that is usually put into an HTML <title>
    # tag. The content represents the bulk of the page and can usually contain
    # whatever HTML you can put in a <body> tag, though the HTML surrounding
    # the content in the template used may impose other requirements.
    #
    # This is a practical example of how simple it can be to create a new page
    # type by subclassing +Stitch::PageTypes::Base+.
    #
    # +PlainPage+ is also the default page type for any page in a Stitch site
    # that doesn't inherit or explicitly set a page type.
    class PlainPage < Base
      file_attributes :title, :content
    end
  end
end

