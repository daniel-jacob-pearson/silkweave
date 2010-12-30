# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = 'stitch'
  s.version = '0.0.1'
  s.author = 'Daniel Pearson'
  s.email = 'daniel@nanoo.org'
  s.licence = 'ISC'
  s.summary =
    'A framework to make a Web site out of a file tree while using templates.'
  s.description =
    'Stitch is a framework for creating a Web site out of a file tree with '   \
    'the help of templates. It is for people who find using a CMS annoying '   \
    'and would rather just edit files and arrange them in folders, but still ' \
    'want to factor out elements that are common to multiple Web pages.'
  s.files = Dir['lib/**/*.rb'] + Dir['README*'] + Dir['bin/*']
  s.executables = ['stitch-static']
  s.add_dependency('actionpack', '>= 3.0.0')
  s.add_dependency('haml', '>= 3.0.0')
  s.has_rdoc = true
end
