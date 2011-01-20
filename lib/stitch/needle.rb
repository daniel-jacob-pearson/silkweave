# encoding: UTF-8

module Stitch
  # @private
  #
  # This class contains only internal implementation for Stitch and is not part
  # of its public interface. It handles most of the heavy lifting of HTTP
  # request handling and template rendering by delegating to the ActionPack
  # library (which is a part of Ruby on Rails). 
  class Needle < ActionController::Metal
    include AbstractController::Layouts
    include ActionController::UrlFor # required for "render :location => foo"
    include ActionController::Helpers
    include ActionController::Rendering
    include ActionController::RackDelegation
    include ActionController::Rescue

    # @return [Stitch::Site] The Web site being served.
    attr_reader :site

    # Since this constructor requires an argument, the inherited +action+
    # method, which calls the constructor without arguments, cannot be used
    # with this class.
    def initialize(site)
      @site = site
      super()
    end

    # The main entry-point for handling an HTTP request with Stitch. It
    # constructs a page object from the path component of the requested URL
    # (using +Stitch::Site#page_for+), then finds the template and layout
    # associated with the page's type (using +Stitch::Needle#template_for+),
    # and renders the template (within the associated layout, if any). The
    # page's template is sought within +self.site.template_path+ and the page's
    # layout is sought within +self.site.template_path.join(":layouts")+. The
    # page object and site object are accessible in the template by way of the
    # respective variables named +@page+ and +@site+.
    def sew
      append_view_path site.template_path
      @page = site.page_for(Rack::Utils.unescape(request.path_info))
      content_type = @page.content_type
      if template = template_for(@page)
        render :template => template, :layout => template_for(@page, ':layouts/')
      else
        raise InternalServerError, 
          "This site's author did not provide a template for " \
          "<code>#{@page.class}</code>, nor is there a default template."
      end
    rescue HTTPError
      raise
    rescue ActionView::Template::Error => e
      raise InternalServerError,
        "In <code>#{site.fspath_to_urlpath e.file_name}</code>, line " \
        "#{e.line_number}: #{e.message}"
    rescue StandardError => error
      raise InternalServerError, error.message
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
        render :status => type, :inline => "<!DOCTYPE html>" \
          "<html><head><meta charset='utf-8' />" \
          "<title>#{type.to_s.titleize}</title></head>" \
          "<body><h1>#{type.to_s.titleize}</h1>#{@error.message}</body></html>"
      end
    end
    rescue_from HTTPError, :with => :http_error_handler

    # Finds and returns the template associated with the given class or the
    # given object's class. It looks for templates in the ":templates"
    # directory within +site.root+. It first looks for a template named after
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
    #   ":layouts/").
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

    # :nodoc:
    # Required for including ActionController::UrlFor.
    def self._routes
      ActionDispatch::Routing::RouteSet.new
    end
  end
end
