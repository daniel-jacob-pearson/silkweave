# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = 'stitch'
  s.version = '0.0.1'
  s.author = 'Daniel Pearson'
  s.email = 'daniel@nanoo.org'
  s.summary = '
    A framework to make a Web site out of a file tree while using templates.
  '.strip
  s.description = <<-DESC.gsub(/^\s+/, '')
    Stitch is a framework for creating a Web site out of a file tree with the
    help of templates.  It is for people who find using a CMS annoying and
    would rather just edit files and arrange them in folders, but still want to
    factor out elements that are common to multiple Web pages.
  DESC
  s.files = Dir['lib/**/*.rb'] + Dir['README*']
  s.add_dependency('actionpack', '>= 3.0.0')
  s.add_dependency('haml', '>= 3.0.0')
end
