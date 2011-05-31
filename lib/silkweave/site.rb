# encoding: UTF-8

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
    # @param [#to_str, #to_path] template_path
    #   The directory that contains the site's templates. By default, the
    #   directory named "templates" in the parent of the site root will be used
    #   for this.
    #
    # @param [#to_str, #to_path] pagetype_path
    #   The directory for user-defined page types. By default, the directory
    #   named "page-types" in the parent of the site root will be used for
    #   this. Any Ruby source files in this directory (but not in its
    #   subdirectories) will be loaded, presumably to define new page types
    #   within the +Silkweave::PageTypes+ module.
    #
    # All arguments must be absolute pathnames. If you pass in a relative
    # pathname, then it will be coerced into an absolute pathname by prefixing
    # "/", which may not produce the result you desire, so you're better off
    # only using pathnames that are already absolute.
    #
    # If you use +Arachne+ directly (and you probably shouldn't), note that
    # creating a +Site+ instance has the side effect of clearing the
    # +middleware+ attribute of the +Arachne+ class.
    def initialize(root, template_path=nil, pagetype_path=nil)
      @root = normalize_path root
      @template_path = if template_path.nil?
        Pathname.new('../templates').expand_path(@root)
      else
        normalize_path template_path
      end
      @pagetype_path = if pagetype_path.nil?
        Pathname.new('../page-types').expand_path(@root)
      else
        normalize_path pagetype_path
      end
      Arachne.middleware.clear
      Arachne.use Middleware::Head
      Arachne.use Middleware::AddSlash, @root.to_s
      Arachne.use Middleware::Length
      Arachne.use ActionDispatch::Static, @root.to_s
      @page_renderer = Arachne.middleware.build('sew') do |env|
        Arachne.new(self).dispatch(:sew, ActionDispatch::Request.new(env))
      end
      Arachne.middleware.clear
      # Load all user-supplied page type classes.
      Dir[@pagetype_path + '*.rb'].each do |page_type|
        require page_type
      end
    end

    # @return [Pathname] The directory that serves as the Web site's root.
    #
    #   All paths requested from the Web site will be resolved into paths within
    #   this directory.
    attr_reader :root

    # @return [Pathname] The directory that contains the site's templates.
    attr_reader :template_path

    # @return [Pathname] The directory for user-defined page types.
    attr_reader :pagetype_path

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
    # known as the page type) is determined by reading a file named
    # "=page-type" found in the directory associated with the requested path.
    # This file must contain nothing more than the name of a class within the
    # +Silkweave::PageTypes+ module. The class so named must implement the
    # interface defined by +Silkweave::AbstractPage+. If the "=page-type" file
    # cannot be read, the path given as the argument and its ancestors are
    # searched for a file named ":page-type", which will be used in the same
    # way. If the parent of +self.root+ is reached without finding a
    # ":page-type" file, then +Silkweave::PageTypes::PlainPage+ will be used as
    # the default page type.
    #
    # @param [#to_str, #to_path] path A path in URL space.
    #
    # @return [AbstractPage] A new instance of one of the classes in the
    #   +Silkweave::PageTypes+ module, initialized with the given +path+.
    #
    # @raise [InternalServerError] if the page type specified in the
    #   "=page-type" or ":page-type" file is not the name of a class in
    #   +Silkweave::PageTypes+.
    def page_for path
      path = normalize_path path
      private_type_file = urlpath_to_fspath(path + '=page-type')
      type_file = if private_type_file.readable?
        private_type_file 
      else
        find_upward(path, ':page-type', StringIO.new('PlainPage'))
      end
      begin
        "Silkweave::PageTypes::#{type_file.read.strip}".constantize.new(path, self)
      rescue NameError, NoMethodError, ArgumentError => error
        type = type_file.read.strip.inspect
        if type_file.is_a? Pathname
          type_file = fspath_to_urlpath(type_file)
        else
          type_file = 'a hard-coded default'
        end
        case error
        when NameError
          reason = 'it does not name a member of the Silkweave::PageTypes module'
        when NoMethodError
          reason = 'it is not the name of a class'
        when ArgumentError
          reason = 'its constructor does not accept parameters correctly'
        else
          reason = "it just ain't"
        end
        raise InternalServerError, <<-MSG.split.join(' ')
          This site's author specified <code>#{type}</code> as the page type
          for <code>#{path}</code>, but that is not a valid page type because
          #{reason}. This page type was specified in <code>#{type_file}</code>.
        MSG
      end
    end

    private

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
      looked = []
      path.ascend do |p|
        fspath = urlpath_to_fspath(p + target)
        return fspath if fspath.readable?
        looked << p
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
      path = SLASH + path if path.relative?
      path
    end

    # :nodoc:
    SLASH = Pathname.new '/'
  end
end
