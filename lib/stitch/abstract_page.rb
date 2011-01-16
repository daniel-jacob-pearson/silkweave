module Stitch
  # +AbstractPage+ defines the interface that must be implemented by all
  # page types (i.e. classes within +Stitch::PageTypes+). A page type defines
  # the capabilities and requirements of the template used to render pages of
  # that type. Specifically, the page type defines the methods that can be
  # called on the +@page+ object given to a template and the content-type (i.e.
  # MIME-type) of the data that the template must produce. The decision of
  # which template to use for a page is also based on its page type (this
  # decision is made by +Stitch::Needle#template_for+).
  #
  # @abstract All methods defined in this class must be implemented entirely by
  #   subclasses and must not call upon the implementations here, since there
  #   are none.
  class AbstractPage
    # Returns a new page object. Page objects are normally created only through
    # the +Stitch::Site#page_for+ factory. 
    #
    # @param [#to_str, #to_path] path The path component of the URL used to
    #   request the page.
    #
    # @param [Stitch::Site] site The Web site to which the page belongs.
    def initialize path, site
      raise NotImplementedError
    end

    # Accessor for the +path+ attribute.
    #
    # The +path+ of a page is the path component of the URL that was used to
    # access the page. This +path+ is a URL path that uniquely identifies a
    # page. Two pages with the same path should be equivalent.
    #
    # @return [#to_str] The URL path that identifies this page.
    def path
      raise NotImplementedError
    end

    # Accessor for the +site+ attribute.
    #
    # Every page belongs to a Web site (represented by a +Stitch::Site+
    # object), whose methods are often needed for the page's rendering.
    #
    # @return [Stitch::Site] The Web site to which this page belongs.
    def site
      raise NotImplementedError
    end

    # The parent of a page is the page associated with the parent of the page's
    # path. For example, the parent of the page for "/x/y/z" should be the page
    # for "/x/y".
    #
    # @return [AbstractPage] The parent of the receiver.
    def parent
      raise NotImplementedError
    end

    # Returns the pages that are found below this page. These pages should have
    # this page's path as their parent's path.
    #
    # @return [Enumerable<AbstractPage>]
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
