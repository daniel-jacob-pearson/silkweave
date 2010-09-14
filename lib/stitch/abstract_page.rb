module Stitch
  # +AbstractPage+ defines the interface that must be implemented by all
  # page types (i.e. classes within +Stitch::PageTypes+). A page type defines
  # the capabilities and requirements of the template used to render pages of
  # that type. Specifically, the page type defines the methods that can be
  # called on the +@page+ object given to a template and the content-type (i.e.
  # MIME-type) of the data that the template must produce. The decision of
  # which template to use for a page is also based on its page type (this
  # decision is made by +Stitch::Controller#template_for+).
  #
  # @abstract All methods defined in this class must be implemented entirely by
  #   subclasses and must not call upon the implementations here, since there
  #   are none.
  class AbstractPage
    # Returns a new page object. Page objects are normally created only through
    # the +Stitch::Utils#page_for+ factory, which passes a single
    # +path+ parameter to the page's constructor. This +path+ is a URL path
    # that uniquely identifies a page. Two pages with the same path should be
    # equivalent.
    #
    # @param [Pathname, #to_str, #to_path] path The path component of the URL
    #   used to request the page.
    #
    # @param [Pathname, #to_str, #to_path] root The filesystem path to the 
    #   site's root directory.
    def initialize path, root
      raise NotImplementedError
    end

    # Accessor for the +path+ attribute.
    #
    # @return [Pathname] 
    def path
      raise NotImplementedError
    end

    # Accessor for the +site_root+ attribute.
    #
    # @return [Pathname] 
    def site_root
      raise NotImplementedError
    end

    # The parent of a page is the page associated with the page's path's parent
    # directory.
    #
    # @return [AbstractPage] The parent of the receiver.
    def parent
      raise NotImplementedError
    end

    # Returns a list of the pages that are found below this page.
    #
    # @return [Array<AbstractPage>]
    def children
      raise NotImplementedError
    end

    # Returns the value of the Content-type HTTP header used for serving this
    # type of page.
    #
    # @return [String] 
    def content_type
      raise NotImplementedError
    end
  end
end
