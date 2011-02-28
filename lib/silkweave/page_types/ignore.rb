# encoding: UTF-8

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
