require 'stitch/page_types/plain_page'

module Stitch
  module PageTypes
    # A front page is functionally identical to a plain page, but since it has
    # a different name, it can use a different template. This is handy in real
    # life, since the front page of many sites looks quite rather different
    # than the other pages on the site.
    class FrontPage < PlainPage
    end
  end
end
