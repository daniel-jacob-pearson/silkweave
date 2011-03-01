# encoding: UTF-8

module Silkweave
  module PageTypes
    class Category < PlainPage
      def members
        ((fspath + '.members').read rescue '').lines.
          map { |l| site.page_for l.chomp }.to_set
      end

    private

      def add path
        ms = members.add(path)
        (fspath + '.members').open('w') { |f| ms.each { |m| f.write(m+"\n") } }
      end

      def remove path
        ms = members.delete(path)
        (fspath + '.members').open('w') { |f| ms.each { |m| f.write(m+"\n") } }
      end
    end

    # This module should be included by any page type that wishes to be
    # associated with a set of categories (which are represented by +Category+
    # pages). Only page types that descend from +Silkweave::PageTypes::Base+
    # should mix in this module, since it relies on the +file_attribute+
    # feature.
    module Categorized
      # +Categorized+ pages have a "categories" file attribute. The file for this
      # attribute must contain the URL paths of zero or more +Category+ pages,
      # with each path on a separate line. Unlike most file attributes, its
      # accessor method returns an Enumerable of Strings rather than a single
      # String.
      def self.included(mod)
        mod.class_eval do
          file_attribute :categories, ''
          raw_categories = self.instance_method :categories
          define_method :categories do ||
            raw_categories.bind(self).call.lines.
              map { |l| site.page_for l.chomp }.
              select { |p| p.is_a? Category }.to_set
          end
        end
      end

      # This method updates the +Category+ pages associated with this page to
      # reflect this page's membership in that category.
      def update_categories
        current_categories = categories
        current_categories.each { |category| category.send(:add, path) }
        (((fspath + '.categories_since_last_update').read rescue '').
          lines.map { |l| site.page_for l.chomp } - current_categories).
            each { |category| category.send(:remove, path) }
        (fspath + '.categories_since_last_update').open('w') { |f|
          current_categories.each { |c| f.write(c+"\n") }
        }
      end
    end
  end
end
