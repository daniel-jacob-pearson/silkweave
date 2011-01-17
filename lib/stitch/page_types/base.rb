require 'set'
require 'facets/denumerable'

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
      include ::Comparable

      # Creates a new page object to access the attributes stored in the
      # filesystem path that corresponds to the given URL path.
      #
      # @param [#to_str, #to_path] path The path component of the URL
      #   used to request the page.
      #
      # @param [Stitch::Site] site The Web site to which the page belongs.
      #
      # @raise [Stitch::NotFound] if the given path does not refer to an
      #   accessible directory in +self.site.root+.
      def initialize path, site
        @path = path.is_a?(::Pathname) ? path : ::Pathname.new(path)
        @site = site
        raise ::Stitch::NotFound, @path.to_s unless fspath.directory?
      end

      # The +path+ of a page is the path component of the URL that was used to
      # access the page. This path corresponds to an existing directory in the
      # filesystem from which files can be read to determine the attributes of
      # the page.
      #
      # @return [Pathname] The URL path that identifies this page.
      attr_reader :path
      alias :urlpath :path

      # @return [Stitch::Site] The Web site to which this page belongs.
      attr_reader :site

      # @return [Pathname] The filesystem path that corresponds to +self.path+.
      def filesystem_path
        @fspath ||= site.urlpath_to_fspath(path)
      end
      alias :fspath :filesystem_path

      # Defines a file-backed attribute for the page type.
      #
      # The attribute's value is the content of a file whose name is "@"
      # followed by the name of the attribute. This file is located in the
      # directory referred to by the page's filesystem path.
      #
      # @param [Symbol] name The name of the attribute to declare.
      #
      # @param [Object] default The value the attribute should have if its file
      #   can't be read.
      #
      # @example A class for pages that have a beverage associated with them.
      #   module Stitch::PageTypes
      #     class Example < Base
      #       file_attribute :beverage, "You must be thirsty without a drink."
      #     end
      #   end
      def self.file_attribute name, default=nil
        define_method name do ||
          (fspath + "@#{name}").read.chomp.html_safe rescue default
        end
        @file_attribute_names ||= Set.new
        @file_attribute_names.add name.to_s
        return
      end

      # Like the +file_attribute+ method, this lets you declare page attributes
      # that are stored in the filesystem path associated with this page.
      # However, +file_attributes+ lets you declare multiple attributes at once
      # and doesn't let you specify a default value. The default value of each
      # attribute declared with this will be +nil+.
      #
      # This method also acts as a getter for the names of the attributes
      # that have been defined for the class (including those just defined as a
      # result of passing in parameters).
      #
      # @param [Array<Symbol>] names The names of the attributes to declare.
      #
      # @return [Enumerable<String>] The names of this class's file attributes.
      #
      # @example This is actually how PlainPage is implemented.
      #   module Stitch::PageTypes
      #     class PlainPage < Base
      #       file_attributes :title, :content
      #     end
      #   end
      def self.file_attributes *names
        names.each { |name| file_attribute name }
        (@file_attribute_names ||= Set.new).to_enum
      end

      # Returns the names of the file attributes defined for this page's type.
      #
      # @return [Enumerable<String>] The names of this page's file attributes.
      def file_attributes
        self.class.file_attributes
      end

      # @return [Time] The time at which one of the page's file attributes was
      # last modified.
      def mtime
        file_attributes.map { |a| fspath + "@#{a}" }.select(&:exist?).
          map(&:mtime).max || fspath.mtime
      end

      # Comparison for value equality. All pages with the same +path+ and
      # +site+ are considered to have the same value.
      #
      # @param [AbstractPage, Object] other The object to compare to this page.
      #
      # @return [Boolean] True if both pages are equal, false if not.
      def eql? other
        return false unless other.is_a? ::Stitch::AbstractPage
        self.site == other.site and self.path == other.path
      end
      alias :== :eql?

      # Comparison for sorting purposes. If the other is also a page, their
      # paths are compared. Otherwise, the other is coerced into a +String+ and
      # compared to this page's path.
      #
      # @param [AbstractPage, Object] other The object to compare to this page.
      #
      # @return [Fixnum] -1 if +other+ is less than the receiver, 0 if they are
      #   equal, and 1 if +other+ is greater.
      def <=> other
        if other.responds_to? :path
          self.path.to_s <=> other.path.to_s
        elsif other.responds_to? :to_s
          self.path.to_s <=> other.to_s
        else
          raise ::ArgumentError,
            "comparison of #{self.class} with #{other.class} failed"
        end
      end

      # Returns a list of the pages that are found below this page.
      #
      # Pages of the +Ignore+ type are, predictably, ignored and thus excluded
      # from this list.
      #
      # @return [Enumerable<AbstractPage>]
      def children
        ::Denumerator.new(fspath.children).
          select { |i| i.directory? }.
          map { |j| site.page_for "#{site.fspath_to_urlpath j}/" rescue nil }.
          reject { |k| k.nil? or k.is_a? ::Stitch::PageTypes::Ignore }
      end

      # Returns the page object for this page's parent.
      #
      # @return [AbstractPage] This page's parent.
      def parent
        site.page_for(path.parent)
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
