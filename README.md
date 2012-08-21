What is Silkweave?
==================

Silkweave is a tiny framework for creating a Web site out of a file tree with
the help of templates. It takes a directory full of your desired site's content
as input and produces the Web site as output. All the content and structure of
the Web site is determined from the content and structure of the file tree by
way of a clear and simple mapping. While this might sound like what any common
Web server will do with a file tree, the use of templates means that you Don't
Repeat Yourself (DRY).

Why Use Silkweave?
==================

Silkweave is designed for creating sites that might otherwise be created with a
CMS, but without the complexity of deploying and managing a CMS and its nearly
inevitable database. The user interface for creating a Web site with Silkweave
is exactly the interface a user normally uses to edit and otherwise manipulate
text files in a filesystem. This allows a Web site author to leverage the vast
array of file and text manipulation tools that every computer user uses.

It works primarily by helping an author factor out HTML code that is common to
multiple Web pages through the use of templates (and layouts and partials). All
content that is particular to a single page is "woven" together with any
content that is shared between pages. The use of a powerful template language
with pertinent helper functions also facilitates the automatic generation of
pages that reuse content that properly belongs to other pages. Such template
programming can be used to create a menu for navigating the site's page
heirarchy or a blog-style list of summaries of other pages.

Silkweave's greatest source of power and flexibility comes from its concept of
page types. When one page has a different type than another page, it can be
rendered with a different template, its data might be organized differently, and
it can exhibit different behavior by responding to different methods within
template code. With the right customizations, you can even produce pages in
formats other than HTML. [concrete examples: front page vs. plain page,
directory index]. Silkweave comes with a variety of general-purpose page types
out of the box, and you can easily add more types of your own design to suit
your own site's special needs. Page types can inherit from each other, allowing
you to reuse the template or other functionality from another page type.

Who Should Use Silkweave?
=========================

Silkweave is intended for people who aren't afraid of writing code to create a
web site. To write and edit content for web pages, you'll just need to know
enough HTML (or Markdown or Textile or something similar) to format your
content. To control the structure and design of a site, you'll need to have a
moderate knowledge of HTML and enough knowledge of Ruby programming to call
methods on objects. To exploit the full range of Silkweave's customization
capabilities, you'll need to know the basics of writing classes in the Ruby
programming language.

Status
======

Silkweave should be considered experimental software in the sense that its
interfaces are not yet guaranteed not to change: I might still judge certain
interfaces to be inadequate for Silkweave's intended uses.

Legal Notice
============

Silkweave was written in 2010-2012 by Daniel Jacob Pearson <daniel@nanoo.org>.

To the extent possible under law, the author has dedicated all copyright and
related and neighboring rights to this software to the public domain worldwide.
This software is distributed without any warranty.

You should have received a copy of the CC0 Public Domain Dedication along with
this software in a file called COPYING.txt. If not, see
<http://creativecommons.org/publicdomain/zero/1.0/>.

<!-- vim:set ft=markdown tw=80: -->
