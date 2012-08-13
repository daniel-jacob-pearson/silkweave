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

require 'silkweave/page_types/base'

module Silkweave
  module PageTypes
    # A plain page has a +@title+ and a chunk of +@content+. The title is a
    # short description of the page that is usually put into an HTML <title>
    # tag. The content represents the bulk of the page and can usually contain
    # whatever HTML you can put in a <body> tag, though the HTML surrounding
    # the content in the template used may impose other requirements.
    #
    # This is a practical example of how simple it can be to create a new page
    # type by subclassing +Silkweave::PageTypes::Base+.
    #
    # +PlainPage+ is also the default page type for any page in a Silkweave site
    # that doesn't inherit or explicitly set a page type.
    class PlainPage < Base
      file_attributes :title, :content
    end
  end
end

