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
require 'silkweave/page_types/categories'
require 'silkweave/page_types/newest_first'

module Silkweave
  module PageTypes
    # The classes in this module allow you to implement a blog with Silkweave.
    module Blog
      # A +Blog::Post+ represents an article contained in a blog.
      class Post < PlainPage
        include Categorized
        include NewestFirst

        # It can be useful to summarize the main content of a blog post so that
        # only the summary is shown for the post when it appears in a listing
        # of many posts.
        file_attribute :summary

        # Returns an enumerator over the comments attached to this blog post.
        # If a block is given, it iterates over each comment and returns the
        # receiver.
        #
        # @yield [comment]
        #
        # @yieldparam [Blog::Comment] comment
        #
        # @return [Enumerable<Blog::Comment>, self]
        def comments &block
          enum = children.select {|x| x.is_a? Comment}.sort.defer
          if block
            enum.each &block
            self
          else
            enum
          end
        end
        alias :each_comment :comments

        def next_newer
          root = Pathname.new '/'
          ancestor = parent
          last_ancestor = nil
          while true
            # A post should normally exist in a parent folder. If it doesn't,
            # then it definitely has no succeeding or preceding post.
            return nil unless ancestor.is_a? Folder
            # If this post has folders or posts as siblings, and those siblings
            # are older than this post, then the newest of these is the next
            # post (in the case of a post) or contains the next post as its
            # first post (in the case of a folder).
            candidate = ancestor.children.select { |x|
              (x.is_a? Post or (x.is_a? Folder and x.posts.first)) and (x != last_ancestor) and (x < self)
            }.sort.last
            case candidate
            when Post
              return candidate
            when Folder
              return candidate.posts.to_a.last
            else
              # If the parent folder has no other valid posts or folders as
              # children, then the parent's parent should be inspected.
              return nil if ancestor.path == root
              last_ancestor = ancestor
              ancestor = ancestor.parent
            end
          end
        end

        def next_older
          root = Pathname.new '/'
          ancestor = parent
          last_ancestor = nil
          while true
            # A post should normally exist in a parent folder. If it doesn't,
            # then it definitely has no succeeding or preceding post.
            return nil unless ancestor.is_a? Folder
            # If this post has folders or posts as siblings, and those siblings
            # are older than this post, then the newest of these is the next
            # post (in the case of a post) or contains the next post as its
            # first post (in the case of a folder).
            candidate = ancestor.children.select { |x|
              (x.is_a? Post or (x.is_a? Folder and x.posts.first)) and (x != last_ancestor) and (x > self)
            }.sort.first
            case candidate
            when Post
              return candidate
            when Folder
              return candidate.posts.first
            else
              # If the parent folder has no other valid posts or folders as
              # children, then the parent's parent should be inspected.
              return nil if ancestor.path == root
              last_ancestor = ancestor
              ancestor = ancestor.parent
            end
          end
        end
      end

      # A +Blog::Folder+ is a collection of +Blog::Posts+. The posts contained
      # by a folder are all the posts that are children of the folder and all
      # posts that are contained by any child folders. Generally, every blog
      # post should have a blog folder as its parent, and every blog folder
      # except the root of the blog should have a folder as its parent. This
      # allows the root page of a blog to yield every post in the blog through
      # its +#posts+ method.
      class Folder < PlainPage
        include NewestFirst

        # Returns an enumerator over the posts contained in this folder.
        # If a block is given, it iterates over each post and returns the
        # receiver.
        #
        # @yield [post]
        #
        # @yieldparam [Blog::Post] post
        #
        # @return [Enumerable<Blog::Post>, self]
        def posts &block
          enum = children.sort.defer do |output, child|
            case child
            when Post
              output << child
            when Folder
              child.posts {|post| output << post}
            end
          end
          if block
            enum.each &block
            self
          else
            enum
          end
        end
        alias :each_post :posts
      end

      # A +Blog::Index+ is meant for use as the front page and root of a blog.
      # It is funtionally identical to a +Blog::Folder+, but since it is a
      # distinct type, a different template can be used for it. For example,
      # this allows you to list all the contained posts when rendering a
      # +Folder+, while only listing the 10 most recent posts when rendering an
      # +Index+.
      class Index < Folder
      end

      # A +Blog::Comment+ represents a comment attached to a blog post.
      class Comment < PlainPage
        include NewestFirst

        # Each comment has +sender_name+ and +sender_email+ file attributes to
        # store the name and email address of the person who submitted the
        # comment.
        file_attributes :sender_name, :sender_email
      end

      # A base class for page types that implement web feeds for a blog.
      class AbstractFeed < Base
        # The content of the +source+ file attribute specifies the 
        # +Blog::Folder+ or the +Blog::Post+ that contains the items for this
        # feed. The value of this attribute must be a URL path that specifies a
        # page that has either the +posts+ method (like a +Folder+) or the
        # +comments+ method (like a +Post+). This URL path can be relative, in
        # which case it is relative to the URL path of this page.
        file_attribute :source, '..'

        # Returns an enumerator over either the posts or comments contained in
        # the page specified with the +source+ file attribute. If a block is
        # given, it iterates over each post or comment (and returns the page
        # serving as the source of this feed).
        #
        # @yield [item]
        #
        # @yieldparam [AbstractPage] item
        #
        # @return [Enumerable<AbstractPage>, AbstractPage]
        def items &block
          src = site.page_for(path + source)
          if src.respond_to? :posts
            src.posts &block
          elsif src.respond_to? :comments
            src.comments &block
          else
            raise ::Silkweave::InternalServerError, "Invalid source for feed: #{src.path}"
          end
        end
        alias :each_item :items
      end

      # This page type lets you implement an RSS feed for a blog.
      #
      # It is the responsibility of the author of the template for this page
      # type to generate code that conforms to the RSS format. This class just
      # gives the template author an API to access the data for the feed.
      class RSSFeed < AbstractFeed
        # Returns the Content-type HTTP header appropriate for RSS.
        #
        # @return [String] <tt>"application/rss+xml"</tt>
        def content_type
          'application/rss+xml'
        end
      end

      # This page type lets you implement an Atom feed for a blog.
      #
      # It is the responsibility of the author of the template for this page
      # type to generate code that conforms to the RSS format. This class just
      # gives the template author an API to access the data for the feed.
      class AtomFeed < AbstractFeed
        # Returns the Content-type HTTP header appropriate for Atom.
        #
        # @return [String] <tt>"application/atom+xml"</tt>
        def content_type
          'application/atom+xml'
        end
      end
    end
  end
end
