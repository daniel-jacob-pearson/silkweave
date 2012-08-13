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
    # A front page is functionally identical to a plain page, but since it has
    # a different name, it can use a different template. This is handy in real
    # life, since the front page of many sites is different enough from the
    # other pages on the site to require a different HTML structure.
    class FrontPage < PlainPage
    end
  end
end
