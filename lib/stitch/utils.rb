module Stitch
  # The methods defined in this module are made available in page templates.
  # You can also mix them into a page type class for use in its implementation.
  # If your page type class inherits from +Stitch::PageTypes::Base+, then this
  # module is already included. These methods require their receiver to have a
  # +site_root+ method that can be called with no arguments and returns a
  # +Pathname+ instance.
  module Utils
    # Converts a filesystem path into a URL path by stripping +site_root+ from
    # beginning of the path. The input need not refer (nor is the output
    # guaranteed to refer) to a file or directory that actually exists or is
    # accessible.
    #
    # @example Assuming +site_root+ is +'/var/www'+,
    #   fspath_to_urlpath '/var/www/foo/bar.jpg' #=> #<Pathname:/foo/bar.jpg>
    #
    # @example A file not in +site_root+ will remain unchanged.
    #   fspath_to_urlpath '/dev/null' #=> #<Pathname:/dev/null>
    #
    # @param [Pathname, #to_str, #to_path] fspath
    #   An absolute path to something on the Web server's real filesystem.
    #
    # @return [Pathname] A path appropriate for requests to the Web server.
    def fspath_to_urlpath fspath
      fspath = Pathname.new fspath unless fspath.is_a? Pathname
      Pathname.new('/') + fspath.relative_path_from(site_root)
    end

    # Converts a URL path into a filesystem path by prepending +site_root+.
    # The input need not refer (nor is the output guaranteed to refer) to a
    # file or directory that actually exists or is accessible.
    #
    # @example Assuming +site_root+ is +'/var/www'+,
    #   urlpath_to_fspath '/foo/bar.jpg' #=> #<Pathname:/var/www/foo/bar.jpg>
    #
    # @example Relative paths are resolved with respect to the root path.
    #   urlpath_to_fspath 'foo/bar.jpg' #=> #<Pathname:/var/www/foo/bar.jpg>
    #
    # @example References to a parent or current directory will resolve.
    #   urlpath_to_fspath '/./foo/../bar.jpg' #=> #<Pathname:/var/www/bar.jpg>
    #
    # @example But attempts to break out of +site_root+ will fail.
    #   urlpath_to_fspath '../../etc/passwd' #=> #<Pathname:/var/www/etc/passwd>
    #
    # @param [Pathname, #to_str, #to_path] urlpath
    #   A path appropriate for requests to the Web server.
    #
    # @return [Pathname] A path to something on the Web server's filesystem.
    def urlpath_to_fspath urlpath
      urlpath = Pathname.new urlpath unless urlpath.is_a? Pathname
      root = Pathname.new '/'
      urlpath = urlpath.relative? ? root+urlpath : urlpath
      urlpath = urlpath.cleanpath # Clears out naughty leading ".." components.
      urlpath = urlpath.relative_path_from root
      site_root + urlpath
    end

    # Returns an object to model a Web page. The class of this object (also
    # known as the page type) is determined by reading a file named
    # "=page-type" found in the directory associated with the requested path.
    # If no such file can be read, the path and its ancestors are searched for
    # a file named ":page-type" until the parent of +site_root+ is reached, at
    # which point +Stitch::PageTypes::PlainPage+ is used as the default page
    # type.
    #
    # @param [Pathname, #to_str, #to_path] path A path in URL space.
    #
    # @return [AbstractPage] A new instance of one of the classes in the
    #   +Stitch::PageTypes+ module, initialized with the given +path+.
    #
    # @raise [InternalServerError] if the page type specified in the
    #   "=page-type" or ":page-type" file is not the name of a class in
    #   +Stitch::PageTypes+.
    def page_for path
      path = Pathname.new path unless path.is_a? Pathname
      private_type_file = urlpath_to_fspath(path + '=page-type')
      type_file = if private_type_file.readable?
        private_type_file 
      else
        find_upward(path, ':page-type', StringIO.new('PlainPage'))
      end
      begin
        "Stitch::PageTypes::#{type_file.read.strip}".constantize.new(path, site_root)
      rescue NameError, NoMethodError, ArgumentError => error
        type = type_file.read.strip.inspect
        if type_file.is_a? Pathname
          type_file = fspath_to_urlpath(type_file)
        else
          type_file = 'a hard-coded default'
        end
        case error
        when NameError
          reason = 'it does not name a member of the Stitch::PageTypes module'
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

    # Checks the given directory for a readable file with the given name. If
    # such a file isn't found, the directory's ancestors (up to and including
    # +site_root+) are checked, starting from the parent and proceeding upward.
    # If none of the ancestors have such a file, a default value is returned.
    #
    # @param path [Pathname] The URL path of the directory from which to start
    #   the search.
    #
    # @param target [#to_s] The name of the file to seek.
    #
    # @param default [Object] The object that will be returned if the sought
    #   file cannot be found.
    #
    # @return [Pathname, Object] Either the filesystem path to the target file,
    #   if it was found, or +default+, if it was not found.
    def find_upward(path, target, default = nil)
      looked = []
      root = Pathname.new '/'
      path.ascend do |p|
        fspath = urlpath_to_fspath(p + target)
        return fspath if fspath.readable?
        looked << p
        break if p == root
      end
      return default
    end
  end
end
