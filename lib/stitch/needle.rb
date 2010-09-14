module Stitch
  # @private
  #
  # This class contains only internal implementation for Stitch and is not part
  # of its public interface. It handles most of the heavy lifting of for HTTP
  # request handling and template rendering by delegating to the ActionPack
  # library (which is a part of Ruby on Rails). 
  class Needle < ActionController::Metal
    include AbstractController::Layouts
    include ActionController::Helpers
    include ActionController::Rendering
    include ActionController::RackDelegation
    include ActionController::Rescue
    include Stitch::Utils
    helper Stitch::Utils

    # Returns the directory on the filesystem that represents the root of the
    # Web site. All paths requested from the Web site will be resolved into
    # paths within this directory.
    #
    # @return [Pathname] The filesystem path to the Web site's root.
    attr_reader :site_root
    helper_method :site_root

    # The class method accessors for +site_root+ exist merely to assign a value
    # to the similarly named instance attribute upon instance construction.
    # This roundabout technique is used instead of simply passing a parameter
    # to the constructor so we can use +ActionController::Metal.action+, which
    # invokes the constructor without arguments.
    def initialize(*)
      @site_root = self.class.site_root
      super
    end

    # @return [Pathname] The filesystem path to the Web site's root.
    def self.site_root
      @root ||= Pathname.new(Dir.pwd)
    end

    # @param [Pathname, #to_str, #to_path] path The filesystem path to the Web
    #   site's root.
    def self.site_root= path
      path = Pathname.new(path) unless path.is_a?(Pathname)
      path = Pathname.new('/') + path if path.relative?
      @root = path
    end

    # The main entry-point for handling an HTTP request with Stitch. It
    # constructs a page object from the path component of the requested URL
    # (using +Stitch::Utils.page_for+), then finds the template and layout
    # associated with the page's type (using +Stitch::Needle#template_for+),
    # and renders the template (within the associated layout, if any). The page
    # object is passed to the template in the form of a variable named +@page+.
    def sew
      append_view_path(site_root + ':templates')
      @page = page_for(Rack::Utils.unescape(request.path_info))
      content_type = @page.content_type
      template = template_for(@page)
      layout = template_for(@page, 'layouts/')
      if template
        render :template => template, :layout => layout
      else
        raise InternalServerError, <<-MSG
          This site's author did not provide a template for
          <code>#{@page.class}</code> nor is there a default template.
        MSG
      end
    end

    # Whenever an +HTTPError+ is raised while generating a page with Stitch,
    # this method is called to render the exception into an HTTP response. This
    # rendering tries to use the template named after the exception's class,
    # inflected with +ActiveSupport::Inflector#underscore+ and prefixed with
    # a colon character (":"). If there is no template with that name, then a
    # built-in fallback is used. The template that renders this error is passed
    # an +@error+ variable that refers to the exception that was raised, and is
    # not passed the +@page+ variable that is normally passed to page templates.
    #
    # @param [Stitch::HTTPError] error The exception that was raised.
    def http_error_handler error
      @error = error
      type = @error.class.name.demodulize.underscore.to_sym
      if template_exists? type.inspect
        render :status => type,
               :template => type.inspect
      else
        render :status => type,
               :inline => "<h1>#{type.to_s.titleize}</h1> #{@error.message}"
      end
    end
    rescue_from HTTPError, :with => :http_error_handler

    # Finds and returns the template associated with the given class or the
    # given object's class. It looks for templates in the ":templates"
    # directory within +site_root+. It first looks for a template named after
    # the class name with "Stitch::PageTypes::" stripped from the start and
    # inflected with +ActiveSupport::Inflector#underscore+. If there is no
    # template with that name, then it climbs up the superclass chain until it
    # finds a template named after the current superclass's stripped and
    # inflected name or until either +Stitch::AbstractPage+ or +nil+ is reached.
    # In the latter case, a final attempt is made to find a template named
    # ":default", but if that template is not found then the function gives up
    # and returns +nil+.
    #
    # @param [Class, Object] object The class or object whose associated
    #   template should be found.
    #
    # @param [String] prefix When searching the view path for a template, this
    #   string will be prefixed to the template name. This can be useful to
    #   search within a certain subdirectory of the template directory (like
    #   "layouts/").
    #
    # @return [String, nil] The name of the template found for the +object+
    #   parameter or nil if no template could be found.
    def template_for object, prefix=''
      klass = object.is_a?(Class) ? object : object.class
      until template_exists?(template = prefix + klass.name.sub(/\AStitch::PageTypes::/, '').underscore)
        klass = klass.superclass
        if !klass || klass == ::Stitch::AbstractPage
          template = nil
          break 
        end
      end
      if template.nil? && template_exists?(prefix + ':default')
        template = prefix + ':default'
      end
      template
    end
    helper_method :template_for
  end
end
