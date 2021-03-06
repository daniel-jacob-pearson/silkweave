# encoding: UTF-8
#
# Silkweave - A framework to make web sites out of file trees with templates.
#
# Written in 2010-2012 by Daniel Jacob Pearson <daniel@nanoo.org>.
#
# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide. This software is distributed without any warranty.
#
# You should have received a copy of the CC0 Public Domain Dedication along with
# this software. If not, see http://creativecommons.org/publicdomain/zero/1.0/.

module Silkweave
  # +AbstractPage+ defines the interface that must be implemented by all
  # page types (i.e. classes within +Silkweave::PageTypes+). A page type defines
  # the capabilities and requirements of the template used to render pages of
  # that type. Specifically, the page type defines the methods that can be
  # called on the +@page+ object given to a template and the content-type (i.e.
  # MIME-type) of the data that the template must produce. The decision of
  # which template to use for a page is also based on its page type (this
  # decision is made by +Silkweave::Arachne#template_for+).
  #
  # @abstract All methods defined in this class must be implemented entirely by
  #   subclasses and must not call upon the implementations here, since there
  #   are none.
  class AbstractPage
    # Returns a new page object. Page objects are normally created only through
    # the +Silkweave::Site#page_for+ factory. 
    #
    # @param [Pathname] path The path component of the URL used to request the
    #   page.
    #
    # @param [Silkweave::Site] site The Web site to which the page belongs.
    def initialize path, site
      raise NotImplementedError
    end

    # Accessor for the +path+ attribute.
    #
    # The +path+ of a page is the path component of the URL that was used to
    # access the page. This +path+ is a URL path that uniquely identifies a
    # page. Two pages with the same path should be equivalent.
    #
    # @return [Pathname] The URL path that identifies this page.
    def path
      raise NotImplementedError
    end

    # Accessor for the +site+ attribute.
    #
    # Every page belongs to a Web site (represented by a +Silkweave::Site+
    # object), whose methods are often needed for the page's rendering.
    #
    # @return [Silkweave::Site] The Web site to which this page belongs.
    def site
      raise NotImplementedError
    end

    # The parent of a page is the page associated with the parent of the page's
    # path. For example, the parent of the page for "/x/y/z" should be the page
    # for "/x/y".
    #
    # @return [AbstractPage] The parent of this page.
    def parent
      raise NotImplementedError
    end

    # Returns the pages that are found below this page in the site hierarchy.
    # These pages should have this page's path as their parent's path.
    #
    # @return [Enumerable<AbstractPage>]
    def children
      raise NotImplementedError
    end

    # Calls the given block for each child of this page (as given by
    # +#children+).
    #
    # @yield [child]
    #
    # @yieldparam [AbstractPage] child
    #
    # @return [self]
    def each_child(&block)
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
