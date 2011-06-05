# encoding: UTF-8

module Silkweave
  module PageTypes
    # Certain page types, like those in a blog, are usually sorted by the
    # time at which they were published (newest first), if possible. This
    # module enables that behavior when mixed into a page type.
    #
    # Note that the implementation of the +#pubtime+ method included in this
    # module relies on the +#fspath+ method, so unless you override +#pubtime+
    # in the including page type, the page type should inherit from
    # +Silkweave::PageTypes::Base+.
    module NewestFirst
      # This attribute represents the time at which the page was published.
      # This is distinct from +mtime+, which is the time at which the page
      # was modified. Technically speaking, this value is taken directly from
      # the modification time of the directory named by this page's
      # filesystem path.
      #
      # @return [Time] The time at which the receiver was published.
      def pubtime
        fspath.mtime
      end

      # Comparison for sorting purposes. Compares to the other object's
      # +pubtime+ attribute, if it has one, otherwise compares to the other
      # object's +mtime+ attribute, if it has one, otherwise inherited
      # comparison rules apply.
      #
      # @param [AbstractPage, Object] other The object to compare to this page.
      #
      # @return [Fixnum] -1 if +other+ is less than the receiver, 0 if they are
      #   equal, and 1 if +other+ is greater.
      def <=> other
        if other.respond_to? :pubtime
          -(self.pubtime <=> other.pubtime)
        elsif other.respond_to? :mtime
          -(self.pubtime <=> other.mtime)
        else
          super
        end
      end
    end
  end
end
