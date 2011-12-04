What is Silkweave?
===============

Silkweave is a tiny framework for creating a Web site out of a file tree with the
help of templates.  It takes a directory full of your desired site's content as
input and produces the Web site as output.  All the content and structure of
the Web site is determined from the content and structure of the file tree by
way of a clear and simple mapping.  While this might sound like what any common
Web server will do with a file tree, the use of templates means that you Don't
Repeat Yourself (DRY).

Why Silkweave?
===========

Its primary function is to help an author factor out HTML code that is common
to multiple Web pages through the use of templates (and layouts and partials).
All content that is particular to a single page is "woven" together with any
content that is shared between pages.  The use of a powerful template language
with pertinent helper functions also facilitates the automatic generation of
page elements based on content that belongs to other pages.  Such template
programming can be used to create a menu for navigating the site's page
heirarchy or a blog-style list of summaries of other pages.

Silkweave is designed for creating sites that might otherwise be created with a
CMS, but without the complexity of deploying and managing a CMS and its nearly
inevitable database.  The user interface for creating a Web site with Silkweave is
exactly the interface a user normally uses to edit and otherwise manipulate
text files in a filesystem.  This allows a Web site author to leverage the vast
array of file and text manipulation tools that every computer user uses.
