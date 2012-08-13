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
    # The +Ignore+ page type can be used to mark directories that should not be
    # considered pages. Specifically, a page of this type does not appear in
    # the list of children for the page's parent (assuming the parent inherits
    # +#children+ from +Silkweave::PageTypes::Base+).
    class Ignore < Base
      # Ignored pages don't have any children.
      #
      # @return [] An empty array.
      def children; [] end
    end
  end
end
