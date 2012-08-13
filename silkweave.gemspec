# encoding: UTF-8

require File.expand_path('../lib/silkweave/version.rb', __FILE__)

Gem::Specification.new do |s|
  s.name = 'silkweave'
  s.version = Silkweave::Version
  s.homepage = 'http://nanoo.org/software/silkweave'
  s.author = 'Daniel Pearson'
  s.email = 'daniel@nanoo.org'
  s.license = 'CC0'
  s.summary =
    'A framework to make a web site out of a file tree while using templates.'
  s.description =
    'Silkweave is a framework for creating a Web site out of a file tree with '   \
    'the help of templates. It is for people who find using a CMS annoying '   \
    'and would rather just edit files and arrange them in folders, but still ' \
    'want to factor out elements that are common to multiple Web pages.'
  s.files = Dir['lib/**/*.rb'] + ['README.md', 'QuickStart.md', 'UNLICENSE', 'bin/silkweave']
  s.executables = ['silkweave']
  s.add_dependency('actionpack', '>= 3.1.0')
  s.add_dependency('rack', '>= 1.3.2')
  s.add_dependency('haml', '>= 3.0.0')
  s.add_dependency('facets', '>= 2.9.0')
  s.has_rdoc = true
end
