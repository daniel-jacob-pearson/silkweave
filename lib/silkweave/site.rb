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

module Silkweave
  # The representation of a Web site served by Silkweave. It provides two main
  # functions: getting object representations of pages within the site (by
  # using the +#page_for+ method) and rendering pages (by using the +#call+
  # method).
  class Site
    # Returns an object that represents a Silkweave-based Web site. Since every
    # +Site+ instance is a Rack (end-point) application, you can use such an
    # instance as the argument to +run+ in a rackup configuration file
    # (+config.ru+), or otherwise integrate it into a Rack-capable Web server.
    #
    # @example In a config.ru file:
    #   run Silkweave::Site.new('/var/www', '/var/www/templates')
    #
    # @example Running as a CGI script:
    #   Rack::Handler::CGI.run Silkweave::Site.new('/home/nancy/public_html')
    #
    # @param [#to_str, #to_path] root
    #   The directory to use as the site's root.
    #
    # @param [Hash] options Optional settings for the +Site+.
    #
    # @option options [#to_str, #to_path] :template_dir ("#{root}/../templates")
    #   The directory that contains the site's templates. By default, the
    #   directory named "templates" in the parent of the site root will be used
    #   for this.
    #
    # @option options [#to_str, #to_path] :pagetype_dir ("#{root}/../page-types")
    #   The directory for user-defined page types. By default, the directory
    #   named "page-types" in the parent of the site root will be used for
    #   this. Any Ruby source files in this directory (but not in its
    #   subdirectories) will be loaded, presumably to define new page types
    #   within the +Silkweave::PageTypes+ module.
    #
    # @option options [#to_str, #to_path] :type_map_file ("#{root}/../type-map.yaml")
    #   The file that contains instructions for mapping page paths to page
    #   types. This file must use the YAML format to specify a list of pairs of
    #   strings. The first member of each pair will be interpreted as a regular
    #   expression. The second member of each pair will be interpreted as the
    #   name of a class (relative to the +Silkweave::PageTypes+ module).
    #   Whenever a path is requested from the +Site+, that path will be matched
    #   against each regular expression in order of appearance. When a match
    #   first succeeds, the class associated with the regular expression will
    #   be used to create the page object for the requested path.
    #
    # @option options [true, false] :enable_editing (false)
    #   If set to true, it will be possible to edit the site by way of HTTP
    #   requests. (This has not yet been implemented.)
    #
    # All pathnames passed as arguments or options must be absolute pathnames.
    # If you pass in a relative pathname, then it will be coerced into an
    # absolute pathname by prefixing "/", which may not produce the result you
    # desire, so you're better off only using pathnames that are already
    # absolute.
    #
    # If you use +Arachne+ directly (and you probably shouldn't), note that
    # creating a +Site+ instance has the side effect of clearing the
    # +middleware+ attribute of the +Arachne+ class.
    def initialize(root, options={})
      @root = normalize_dir root
      defaults = {
        :template_dir => @root + '../templates',
        :pagetype_dir => @root + '../page-types',
        :type_map_file => @root + '../type-map.yaml',
        :enable_editing => false
      }
      options = defaults.merge(options)
      @template_dir = normalize_dir options[:template_dir]
      @pagetype_dir = normalize_dir options[:pagetype_dir]
      @type_map_file = normalize_path options[:type_map_file]
      @type_map = nil
      @type_map_updated_at = -1.0/0.0 # negative infinity
      Arachne.middleware.middlewares.clear
      Arachne.use Middleware::Head
      Arachne.use Middleware::AddSlash, @root.to_s
      Arachne.use Rack::ContentLength
      Arachne.use ActionDispatch::Static, @root.to_s
      @page_renderer = Arachne.middleware.build(:weave) do |env|
        Arachne.new(self).dispatch(:weave, ActionDispatch::Request.new(env))
      end
      Arachne.middleware.middlewares.clear
      # Load all user-supplied page type classes.
      Dir[@pagetype_dir + '*.rb'].each do |page_type|
        require page_type
      end
    end

    # @return [Pathname] The directory that serves as the Web site's root.
    #
    #   All paths requested from the Web site will be resolved into paths within
    #   this directory.
    attr_reader :root

    # @return [Pathname] The directory that contains the site's templates.
    attr_reader :template_dir

    # @return [Pathname] The directory for user-defined page types.
    attr_reader :pagetype_dir

    # @return [Pathname] The file that specifies the type for pages in this site.
    attr_reader :type_map_file

    def editing_enabled?
      @enable_editing
    end

    # The #call method required by the Rack specification for Rack
    # applications.
    #
    # @param [Hash] env An environment as defined by the Rack spec.
    #
    # @return [(#to_i, {String => String}, #each)] A Rack-conformant response.
    def call(env)
      @page_renderer.call(env)
    end

    # Converts a filesystem path into a URL path by stripping +self.root+ from
    # the beginning of the path. The input need not refer (nor is the output
    # guaranteed to refer) to a file or directory that actually exists or is
    # accessible.
    #
    # @example Assuming +self.root+ is +'/var/www'+,
    #   fspath_to_urlpath '/var/www/foo/bar.jpg' #=> #<Pathname:/foo/bar.jpg>
    #
    # @example A file not in +self.root+ will remain unchanged.
    #   fspath_to_urlpath '/dev/null' #=> #<Pathname:/dev/null>
    #
    # @param [#to_str, #to_path] fspath
    #   A path to something on the Web server's real filesystem.
    #
    #   This must be an absolute pathname. If you pass in a relative pathname,
    #   then it will be coerced into an absolute pathname by prefixing "/",
    #   which may not produce the result you desire, so you're better off only
    #   using pathnames that are already absolute.
    #
    # @return [Pathname] A path appropriate for requests to the Web server.
    def fspath_to_urlpath fspath
      SLASH + normalize_path(fspath).relative_path_from(self.root)
    end

    # Converts a URL path into a filesystem path by prepending +self.root+.
    # The input need not refer (nor is the output guaranteed to refer) to a
    # file or directory that actually exists or is accessible.
    #
    # @example Assuming +self.root+ is +'/var/www'+,
    #   urlpath_to_fspath '/foo/bar.jpg' #=> #<Pathname:/var/www/foo/bar.jpg>
    #
    # @example Relative paths are resolved with respect to +self.root+.
    #   urlpath_to_fspath 'foo/bar.jpg' #=> #<Pathname:/var/www/foo/bar.jpg>
    #
    # @example References to a parent or current directory will resolve.
    #   urlpath_to_fspath '/./foo/../bar.jpg' #=> #<Pathname:/var/www/bar.jpg>
    #
    # @example But attempts to break out of +self.root+ will fail.
    #   urlpath_to_fspath '../../etc/passwd' #=> #<Pathname:/var/www/etc/passwd>
    #
    # @param [#to_str, #to_path] urlpath
    #   A path appropriate for requests to the Web server.
    #
    # @return [Pathname] A path to something on the Web server's filesystem.
    def urlpath_to_fspath urlpath
      self.root + normalize_path(urlpath).cleanpath.relative_path_from(SLASH)
    end

    # Returns an object to model a Web page. The class of this object (also
    # known as the page type) is determined by consulting the type mapping
    # configuration file. If this file doesn't exist, then
    # +Silkweave::PageTypes::PlainPage+ will be used as the type of every page.
    #
    # @param [#to_str, #to_path] path A path in URL space.
    #
    # @return [AbstractPage] A new instance of one of the classes in the
    #   +Silkweave::PageTypes+ module, initialized with the given +path+.
    #
    # @raise [InternalServerError] if the page type specified for the page is
    #   not a valid page type.
    def page_for path
      path = normalize_dir path
      page_type = (type_map.find {|pattern,type| pattern.match path} || [nil, 'PlainPage'])[1]
      begin
        "Silkweave::PageTypes::#{page_type}".constantize.new(path, self)
      rescue NameError, NoMethodError, ArgumentError => error
        reason = case error
          when NameError
            "it does not name a member of the Silkweave::PageTypes module"
          when NoMethodError
            "it is not the name of a class"
          when ArgumentError
            "its constructor does not accept parameters correctly"
          else
            "it just ain't"
          end
        raise InternalServerError, <<-MSG.split.join(' ')
          This site's author specified <code>#{page_type.inspect}</code> as the
          page type for <code>#{path}</code>, but that is not a valid page type
          because #{reason}.
        MSG
      end
    end

    # @private
    #
    # Returns a code-like, yet human-readable string representation of the
    # site. This makes +Site+ objects look prettier in irb.
    def inspect
      "#<#{self.class} @root=#{@root.to_s.inspect}, " +
        "@template_dir=#{@template_dir.to_s.inspect}, " +
        "@pagetype_dir=#{@pagetype_dir.to_s.inspect}, " +
        "@type_map_file=#{@type_map_file.to_s.inspect}>"
    end

    # @private
    #
    # Two sites are equal if they were initialized with the same paths.
    def eql? other
      return false unless other.is_a? Silkweave::Site
      @root == other.root and
        @template_dir == other.template_dir and
        @pagetype_dir == other.pagetype_dir and
        @type_map_file == other.type_map_file
    end
    alias :== :eql?

    # @private
    #
    # Two sites have the same hash code if they were initialized with the same
    # paths.
    def hash
      @root.hash ^ @template_dir.hash ^ @pagetype_dir.hash ^ @type_map_file.hash
    end

    private

    # Loads the page type mapping from the type map file.
    #
    # @return [Array<Array(Regexp,String)>] 
    def type_map
      return [] unless @type_map_file.exist?
      if not @type_map or @type_map_updated_at < @type_map_file.mtime
        @type_map = @type_map_file.open {|f| check_type_map YAML::load f}.
          map {|pattern,type| [Regexp.new(pattern), type]}
        @type_map_updated_at = Time.now
      end
      @type_map
    end

    # Raises hell if the type map file isn't formatted correctly.
    #
    # @param [Object] An object to check for validity as a type map.
    #
    # @return [Object] The same object that was passed in.
    #
    # @raise [RuntimeError] if the type map is somehow invalid.
    def check_type_map obj
      unless obj.is_a? Array and obj.all? {|i| i.is_a? Array and i.length == 2 and i.all? {|j| j.is_a? String}}
        raise 'the type map must be a sequence of pairs of strings' 
      end
      obj
    end

    # Checks the given directory for a readable file with the given name. If
    # such a file isn't found, the directory's ancestors (up to and including
    # +self.root+) are checked, starting from the parent and proceeding upward.
    # If none of the ancestors have such a file, a default value is returned.
    #
    # @param [Pathname] path The URL path of the directory from which to start
    #   the search.
    #
    # @param [#to_s] target The name of the file to seek.
    #
    # @param [Object] default The object that will be returned if the sought
    #   file cannot be found.
    #
    # @return [Pathname, Object] Either the filesystem path to the target file,
    #   if it was found, or +default+, if it was not found.
    def find_upward(path, target, default = nil)
      path.ascend do |p|
        fspath = urlpath_to_fspath(p + target)
        return fspath if fspath.readable?
        break if p == SLASH
      end
      return default
    end

    # Ensures that the argument is a +Pathname+ object and is an absolute path.
    #
    # @param [#to_str, #to_path] path The path to normalize.
    #
    # @return [Pathname] The normalized path.
    def normalize_path path
      path = Pathname.new path unless path.is_a? Pathname
      return path.expand_path('/')
    end

    # Ensures that the argument is a +Pathname+ object and is an absolute path
    # and ends with a slash ("/").
    #
    # @param [#to_str, #to_path] path The path to normalize.
    #
    # @return [Pathname] The normalized path.
    def normalize_dir path
      path = normalize_path path
      s = path.to_s
      path = Pathname.new(s + '/') if s[-1..-1] != '/'
      return path
    end

    # :nodoc:
    SLASH = Pathname.new '/'
  end
end
