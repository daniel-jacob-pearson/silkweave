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

require 'silkweave/page_types/plain_page'

module Silkweave
  module PageTypes
    # A +Category+ is a page that can be associated with any page whose type
    # includes the +Categorized+ module. All pages associated with a +Category+
    # are considered members of the +Category+.
    class Category < PlainPage
      # @return [Set<Categorized>] The pages that belong to this +Category+.
      def members
        paths = member_paths
        paths_to_rewrite = paths.dup
        rewrite = false
        result = Set.new
        paths.each do |path|
          page = site.page_for path rescue nil
          if page.is_a? Categorized
            result << page
          else
            paths_to_rewrite.delete path
            rewrite = true
          end
        end
        rewrite_members paths_to_rewrite if rewrite
        return result
      end

      private

      # @return [Enumerable<String>] The paths of the pages that belong to this +Category+.
      def member_paths
        ((fspath + '.members').read rescue '').lines.map { |l| l.chomp }.to_set
      end

      # Adds a page to this +Category+.
      #
      # @param [String] path The URL path of the page to be added.
      def add_member p
        rewrite_members member_paths.add(p)
      end

      # Removes a page from this +Category+.
      #
      # @param [String] path The URL path of the page to be removed.
      def delete_member p
        rewrite_members member_paths.delete(p)
      end

      # Rewrites the file that stores the list of members for this +Category+.
      #
      # @param [Enumerable<String>] members The URL paths of the members.
      def rewrite_members members
        (fspath + '.members').open('w') {|f| members.each {|m| f.puts(m)}}
        return
      end
    end

    # This module should be included by any page type that wishes to be
    # associated with a set of categories (which are represented by +Category+
    # pages). Only page types that descend from +Silkweave::PageTypes::Base+
    # should mix in this module, since it relies on the +#fspath+ method and
    # makes use of files in the directory returned by +#fspath+.
    module Categorized
      # +Categorized+ pages have a "categories" file attribute. The file for
      # this attribute must contain the URL paths of zero or more +Category+
      # pages, with each path on a separate line. Unlike most file attributes,
      # its accessor method returns a Set of pages rather than a String.
      #
      # @return [Set<Category>] The categories that apply to this page.
      def categories
        update_categories || categories_without_update
      end

      # @private
      #
      # Make sure the relevant categories are updated as soon as possible.
      def initialize(*)
        super
        update_categories
      end

      # @private
      #
      # Make sure "categories" is counted as a file attribute even though it is
      # not implemented with +#file_attribute+.
      def self.included(mod)
        mod.class_eval do
          @file_attribute_names ||= Set.new
          @file_attribute_names.add 'categories'
        end
      end

      private

      # This does the actual work of accessing the category information,
      # decoupled from the process of making sure the categories are updated.
      #
      # @return [Set<Category>] The categories that apply to this page.
      def categories_without_update
        ((fspath + '@categories').read rescue '').lines.
          map { |l| site.page_for l.chomp rescue nil }.
          select { |p| p.is_a? Category }.to_set
      end

      # This method updates the +Category+ pages associated with this page to
      # reflect this page's membership in that category.
      #
      # @return [Set<Category>, nil] The categories that apply to this page, or
      #   nil if no update was needed.
      def update_categories
        categories_file = fspath + '@categories'
        update_file = fspath + '.categories_since_last_update'
        if categories_file.exist?
          if !update_file.exist? or
              update_file.mtime < categories_file.mtime or
              update_file.mtime < fspath.ctime
          then
            current_categories = categories_without_update
            current_categories.each { |category| category.send(:add_member, path.to_s) }
            previous_categories = (update_file.read rescue '').lines.
              map { |l| site.page_for l.chomp rescue nil }.
              select { |p| p.is_a? Category }.to_set
            (previous_categories - current_categories).
              each { |category| category.send(:delete_member, path.to_s) }
            update_file.open('w') { |f|
              current_categories.each { |c| f.puts(c.path) }
            }
            return current_categories
          end
        end
        return nil
      end
    end
  end
end
