module Jekyll
  class ArchivePage
    include Convertible

    attr_accessor :site, :pager, :name, :ext, :basename, :dir, :data, :content, :output

    # Initialize new ArchivePage
    # +site+ is the Site
    # +month+ is the month
    # +posts+ is the list of posts for the month
    #
    # Returns <ArchivePage>
    def initialize(site, month, posts)
      @site = site
      @month = month
      self.ext = '.html'
      self.basename = 'index'
      self.content = <<-EOS
{% for post in page.posts %}
  {% assign post = post %}
  {% include post.html %}
{% endfor %}
EOS
      self.data = {
        'layout' => 'default',
        'title' => "WyeWorks Blog",
        'subtitle' => "The Team's Voice",
        'posts' => posts
      }
    end

    # Add any necessary layouts
    # +layouts+ is a Hash of {"name" => "layout"}
    # +site_payload+ is the site payload hash
    #
    # Returns nothing
    def render(layouts, site_payload)
      payload = {
        "page" => self.to_liquid,
        "paginator" => pager.to_liquid
      }.deep_merge(site_payload)
      do_layout(payload, layouts)
    end

    def url
      File.join("/", @month, "index.html")
    end
    
    def to_liquid
      self.data.deep_merge({
                             "url" => self.url,
                             "content" => self.content
                           })
    end

    # Write the generated page file to the destination directory.
    # +dest_prefix+ is the String path to the destination dir
    # +dest_suffix+ is a suffix path to the destination dir
    #
    # Returns nothing
    def write(dest_prefix, dest_suffix = nil)
      dest = dest_prefix
      dest = File.join(dest, dest_suffix) if dest_suffix
      FileUtils.mkdir_p(dest)
      # The url needs to be unescaped in order to preserve the
      # correct filename
      path = File.join(dest, CGI.unescape(self.url))
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w') do |f|
        f.write(self.output)
      end
    end

    def html?
      true
    end

    def destination(dest)
      # The url needs to be unescaped in order to preserve the correct
      #   # filename.
      path = File.join(dest, CGI.unescape(self.url))
      path = File.join(path, "index.html") if self.url =~ /\/$/
      path
    end
  end
end
