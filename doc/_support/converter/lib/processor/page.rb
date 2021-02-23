# FIXME : re-read, grok, re-write this class.
# This was hoisted into a class quickly for the MVP.
module Processor
  class Page < Base
    def initialize(
      contents,
      skip_sitemap: false,
      class_name: "",
      root_relative:,
      relative_input: nil,
      out_path:,
      page:
    )
      @@sitemap ||= []
      @contents = contents
      @skip_sitemap = skip_sitemap

      @class_name = class_name
      @root_relative = root_relative
      @relative_input = relative_input
      @out_path = out_path
      @page = page

    end

    def self.from_string(contents, out_path:, **opts)
      puts "[c] #{out_path}"
      self.new(contents, **opts, skip_sitemap: true, out_path: out_path)
    end

    def self.from_file(input_file)
      puts "[c] #{input_file}"

      # FIXME : remove this hardcoded html output assumption...
      relative_out = input_file.sub(/^#{$options["root"]}/, "").sub(/\..*/, ".html")

      # Used for `edit` links and such
      relative_input = input_file.sub(/^#{$options["root"]}/, "")

      # Figure out the relative location of the current file, to root.
      # Global links might be relative.
      root_relative = File.dirname(relative_out).gsub(/^\.$/, "").gsub(/[^\/]+/, "..")
      if root_relative != "" then
        root_relative = root_relative + "/"
      end

      out_path = File.join(
        $options["output_dir"],
        relative_out
      )

      class_name = relative_out.sub(/\..*$/, "").gsub(/[^a-zA-Z0-9_-]/, "_")

      return self.new(
        File.read(input_file),
        class_name: class_name,
        root_relative: root_relative,
        page: relative_out,
        out_path: out_path,
        relative_input: relative_input,
      )
    end

    def make_page()
      # Create a document
      @doc = load_adoc(@contents)

      # Prepare output, to make next steps more readable.
      @output = @doc.convert

      # Adds necessary stuff in <head />
      @output = Processor::Head.new(@page, @root_relative).append_to_head(@output)

      # Force the site header on the generated page.
      @output = Processor::Header.new(@page, @root_relative).append_header(@output)

      # TODO : Review once we have more content written.
      #        The remaining issue is with styling.
      # # Force the page TOC on the generated page.
      # @output = Processor::TOC.new(doc).insert_toc(@output)

      # Force the site footer on the generated page.
      @output = Processor::Footer.new(
        @doc,
        @page,
        @root_relative,
        source_file: @relative_input
      ).append_footer(@output)

      # Then, insert the desired class name on the body tag.
      @output = @output.sub(/<body class="/, '<body class="'+ @class_name +' ')


      FileUtils.mkdir_p(File.join(
        $options["output_dir"],
        File.dirname(@page)
      ))

      if @doc.attributes["special"] then
        special = @doc.attributes["special"].gsub(/[^a-zA-Z0-9_-]/, "")
        send("handle_special_#{special}")
      end

      # Register the page to the sitemap
      unless @skip_sitemap then
        @@sitemap << Sitemap::Entry.new(@page, @doc)
      end

      # Write the file
      @doc.write(@output, @out_path)

      # Ensure we return the new document...
      # It'll be used for indexing all pages.
      @doc
    end

    def handle_special_homepage()
      news_items = Article.get_article_paths().map do |filename|
        article = Article.new(filename)
        article.output
      end[0..9].join("\n")
      @output.sub!('<!-- {NEWS_ITEMS} -->', news_items)
    end

    def handle_special_all_news()
      template = ERB.new(File.read(File.join($options["root"], "_support/all_news.erb")))
      news_items = Article.get_article_paths().map do |filename|
        {
          article: Article.new(filename),
          # Assumes links will be relative to the root of the site.
          url: filename.sub(/\.adoc$/, ".html").sub(%r{^#{Dir.pwd}}, "")
        }
      end
      @output.sub!(
        '<!-- {NEWS_ITEMS} -->',
        template.result(binding)
      )
    end

    def handle_special_news()
      @output.sub!(/<body class="/, '<body class="news-article ')

      template = ERB.new(File.read(File.join($options["root"], "_support/news_article_header.erb")))

      image = @doc.attributes["image"]
      image = nil if image == ""
      header_styles =
        if @doc.attributes["header_prefers"] then
          " background-position: #{@doc.attributes["header_prefers"]} center;"
        else
          ""
        end
      header = template.result(binding)

      pos = @output.index('<div id="content"')
      @output.insert(pos, header)
    end

    def self.get_sitemap
      @@sitemap
    end
  end
end
