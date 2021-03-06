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
  module PageTypes
    # Causes a page type to be sorted by time of publication.
    #
    # Certain page types, like those in a blog, are usually sorted by the
    # time at which they were published (newest first). This module enables
    # that behavior when mixed into a page type.
    #
    # Note that the implementation of the +#pubtime+ method included in this
    # module relies on the +#fspath+ and +#mtime+ methods, so unless the
    # including page type overrides +#pubtime+, the including page type should
    # inherit from +Silkweave::PageTypes::Base+ (or implement its own +#fspath+
    # and +#mtime+ methods).
    module NewestFirst
      # This attribute represents the time at which a page was published. This
      # is the same as the page's modification time (which is accessed with
      # +#mtime+) unless the directory named by the page's filesystem path
      # contains a file named ":publication-date", in which case the
      # modification time of that file will be returned instead.
      #
      # @return [Time] The time at which the receiver was published.
      def pubtime
        pub_file = fspath + ':publication-date'
        if pub_file.exist?
          pub_file.mtime
        else
          mtime
        end
      end

      # Comparison for sorting purposes, such that newer pages are lesser than
      # older pages. Compares to the other object's +pubtime+ attribute, if it
      # has one, otherwise compares to the other object's +mtime+ attribute, if
      # it has one, otherwise inherited comparison rules apply.
      #
      # @param [AbstractPage, Object] other The object to compare to this page.
      #
      # @return [Fixnum] -1 if +other+ is newer than the receiver, 0 if they are
      #   of equal age, and 1 if +other+ is older.
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
