module Stitch
  module PageTypes
    # +Stitch::PageTypes::Base+ is meant to serve as a base class for deriving
    # new page types. It's not so useful when used as a page type directly. It
    # provides all the basic machinery needed for defining page types that
    # represent Web pages whose data are stored in the filesystem. Any page
    # type for Stitch should probably inherit from this class as long as it
    # follows the Stitch conventions regarding storing page data in the
    # filesystem.
    class Base < ::Stitch::AbstractPage
      include ::Stitch::Utils
      include ::Comparable

      # The +path+ of a page is the path component of the URL that was used to
      # access the page. This path corresponds to an existing directory in the
      # filesystem from which files can be read to determine the attributes of
      # the page.
      #
      # @return [Pathname] The URL path that identifies this page.
      attr_reader :path
      
      # The +site_root+ is the directory on the filesystem that represents the
      # root of the Web site. All paths requested from the Web site will be
      # resolved into paths within this directory.
      #
      # @return [Pathname] The filesystem path to the Web site's root.
      attr_reader :site_root

      # Creates a new page object to access the attributes stored in the
      # filesystem path that corresponds to the given +path+ (which is a URL
      # path).
      #
      # @param [Pathname, #to_str, #to_path] path The path component of the URL
      #   used to request the page.
      #
      # @param [Pathname, #to_str, #to_path] root The filesystem path to the
      #   site's root directory.
      #
      # @raise [NotFound] if the given path does not refer to an accessible
      #   directory in +site_root+.
      def initialize path, root
        @site_root = root.is_a?(::Pathname) ? root : ::Pathname.new(root)
        @path = path.is_a?(::Pathname) ? path : ::Pathname.new(path)
        raise ::Stitch::NotFound, path.to_s unless urlpath_to_fspath(@path).directory?
      end

      # Defines an attribute for the page type. The attribute's value is the
      # content of a file whose name is "@" followed by the name of the
      # attribute. This file is located in the directory referred to by the
      # page's filesystem path.
      #
      # @param [Symbol] name The name of the attribute to declare.
      #
      # @param [Object] default The value the attribute should have if its file
      #   can't be read.
      #
      # @example
      #   module Stitch::PageTypes
      #     class Example < Base
      #       page_attribute :favorite_drink, "A favorite drink was not chosen."
      #     end
      #   end
      def self.page_attribute name, default=nil
        define_method name do ||
          (urlpath_to_fspath(path) + "@#{name}").read.chomp.html_safe rescue default
        end
        return
      end

      # Like the +page_attribute+ method, this lets you declare page attributes
      # that are stored in the filesystem path associated with this page.
      # However, +page_attributes+ lets you declare multiple attributes at once
      # and doesn't let you specify a default value. The default value of each
      # attribute declared with this will be +nil+.
      #
      # @param [Array<Symbol>] names The names of the attributes to declare.
      #
      # @example 
      #   module Stitch::PageTypes
      #     class PlainPage < Base
      #       page_attributes :title, :content
      #     end
      #   end
      def self.page_attributes *names
        names.each { |name| page_attribute name }
        return
      end

      # Compares one page to another. Pages with identical +path+ attributes
      # are considered identical.
      #
      # @param [AbstractPage] other The page to compare to this page.
      #
      # @return [Fixnum] -1 if +other+ is less than the receiver, 0 if they are
      #   equal, and 1 if +other+ is greater.
      def <=> other
        self.path <=> other.path
      end

      # Returns a list of the pages that are found below this page.
      #
      # @return [Array<AbstractPage>]
      def children
        urlpath_to_fspath(path).children.
          select { |i| i.directory? and not i.basename.to_s =~ /\A[:_]/ }.
          map { |j| page_for "#{fspath_to_urlpath j}/" }.
          reject { |k| k.is_a? ::Stitch::PageTypes::Ignore }
      end

      # Returns the page object for this page's parent.
      #
      # @return [AbstractPage] This page's parent.
      def parent
        page_for(@path.parent)
      end

      # The Content-type HTTP header used for serving this type of page.
      #
      # @return [String] <tt>"text/html"</tt>
      #
      # Override this if you are implementing a page type that renders into a
      # format other than HTML.
      def content_type
        'text/html'
      end
    end
  end
end
