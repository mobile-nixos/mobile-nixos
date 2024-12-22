require "date"

module Processor
  # TODO: common base class or mixin with Sitemap
  class RSS
    Path = /^news\//
    include ERB::Util

    def to_rss(entries)
      entry_template = ERB.new(File.read(File.join($options["root"], "_support/rss_entry.xml.erb")))
      item_nodes = entries.map do |entry|
        entry_template.result(binding)
      end

      document_template = ERB.new(File.read(File.join($options["root"], "_support/rss.xml.erb")))
      document_template.result(binding)
    end

    attr_reader :sitemap

    def strip_unneecessary(contents)
      contents
        .gsub(/<header.*<\/header>/m, "")
        .gsub(/<footer.*<\/footer>/m, "")
    end

    def full_url(path)
      [
        "https://mobile-nixos.github.io",
        path
      ].join("/")
    end

    def initialize(sitemap)
    end

    def generate()
      puts "[S] Generating RSS feed..."
      entries = Article.get_article_paths().map do |filename|
        entry = Article.new(filename)
        {
          title: entry.title,
          url: full_url(entry.out_path),
          date: entry.date,
          contents: strip_unneecessary(entry.output),
        }
      end

      return unless entries.length > 0

      # Not producing RSS for now.
      # File.open(File.join($options["output_dir"], "index.xml"), "w") do |file|
      #   file.write(to_rss(entries))
      # end
    end
  end
end
