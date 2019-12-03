module Processor
  class Article < Base
    attr_reader :relative_filename

    def out_path()
      relative_filename
    end

    def initialize(filename)
      # FIXME: assumption of $ROOT/news
      @relative_filename = "news/" + filename.split("/").last
      @relative_filename = relative_filename.sub(/\..*$/, ".html")
      @root_relative = ""

      @doc = load_adoc(File.read(filename), standalone: false)
    end

    def output()
      contents = @doc.convert
      date = @doc.attributes["revdate"]
      image = @doc.attributes["image"]
      title = @doc.doctitle
      url = @relative_filename
      header_styles =
        if @doc.attributes["header_prefers"] then
          " background-position: #{@doc.attributes["header_prefers"]} center;"
        else
          ""
        end

      template = ERB.new(File.read(File.join($options["root"], "_support/news_article.erb")))
      template.result(binding)
    end

    def self.get_article_paths()
      articles = Dir.glob(File.join($options["root"], "news/*.adoc")).sort.reverse
    end
  end
end

