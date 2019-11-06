module Processor
  class Article < Base
    attr_reader :relative_filename

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

      template = ERB.new(File.read(File.join($options["root"], "_support/news_article.erb")))
      template.result(binding)
    end
  end
end

