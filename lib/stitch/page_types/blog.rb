# encoding: UTF-8

require 'stitch/page_types/plain_page'
require 'stitch/page_types/categories'

module Stitch
  module PageTypes
    # The classes in this module allow you to implement a blog with Stitch.
    module Blog
      class Post < PlainPage
        include Categorized
        file_attribute :summary

        # @return [Time] The time at which the post was published.
        def pubtime
          fspath.mtime
        end

        # Blog posts are preferentially sorted by the time at which they were
        # published.
        def <=> other
          if other.respond_to? :pubtime
            self.pubtime <=> other.pubtime
          elsif other.respond_to? :mtime
            self.pubtime <=> other.mtime
          else
            super
          end
        end
      end

      class Folder < PlainPage
        def posts
          children.select { |i| i.is_a? Post or i.is_a? Folder }.
            reduce([]) { |p,i| p.concat(i.is_a? Folder ? i.posts : [i]) }
        end
      end

      class AbstractFeed < Base
        file_attribute :source, '..'
        def posts
          src = site.page_for(path + source)
          if src.respond_to? :posts
            src.posts
          elsif src.respond_to? :comments
            src.comments
          else
            raise ::Stitch::InternalServerError
          end
        end
      end

      class RSSFeed < AbstractFeed
        def content_type
          'application/rss+xml'
        end
      end

      class AtomFeed < AbstractFeed
        def content_type
          'application/atom+xml'
        end
      end
    end
  end
end
