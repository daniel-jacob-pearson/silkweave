# encoding: UTF-8

module Stitch
  module PageTypes
    class Category < PlainPage
      def members
        # FIXME
      end
    end
    module Categorized
      def self.included(mod)
        mod.class_eval do
          file_attribute :categories, ''
          raw_categories = self.instance_method :categories
          define_method :categories do ||
            raw_categories.bind(self).call.lines { |l| site.page_for l.chomp }.
              select { |p| p.is_a? Category }.to_set
          end
        end
      end
    end
  end
end
