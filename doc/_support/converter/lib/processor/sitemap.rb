module Processor
  # TODO : configurable blacklist
  Blacklist = [
    /^news\//,
  ]

  class Sitemap
    attr_reader :sitemap

    def initialize(sitemap)
      index, rest = sitemap.partition { |entry| entry.path == "index.html" }
      sitemap = index.concat(rest)

      @sitemap = normalize_sitemap(sitemap)
    end

    # Given a list of sitemap entries
    #  * Filters blacklisted entries
    #  * Sort entries
    #  * Feeds sub-sections their pages
    def normalize_sitemap(sitemap)
      sitemap = sitemap.select do |entry|
        !Blacklist.any? { |patt| entry.path.match(patt) }
      end.sort do |a, b|
        a_ = a.path.split("/")
        b_ = b.path.split("/")

        if (a_.length == 1 or b_.length == 1) and a_.length != b_.length then
          # Prefer sorting folder-less paths first
          a_.length <=> b_.length
        else
          # Everything else by path name
          normalize_path_for_sorting(a.path) <=> normalize_path_for_sorting(b.path)
        end
      end

      # Make pairs of sub-section prefix, and their sitemap entry.
      indexes = sitemap
        .select { |entry| entry.sitemap_index? }
        .map { |entry| [entry.path.sub(/index.html$/, ""), entry] }
        .sort { |a, b| b.first <=> a.first }

      # Split sitemap entries
      sub, sitemap = sitemap.partition do |entry|
        # Match on index.html-less paths, though ensure there is something
        # after the matched path.
        # We do not want /subsection/index.html to match, while /subsection/foo.html should.
        indexes.any? do |path, section|
          if entry.path.sub(/index.html$/, "").match(/^#{path}.+/)
            # Eww... we're mutating the section in a `partition` and `any?`...
            # Though, pragmatically we know this is where we want it.
            section.entries << entry
          end
        end
      end

      sitemap
    end

    # Given a path name, lightly manipulate for sorting.
    # Mainly, strips index.html.
    def normalize_path_for_sorting(path)
      path.sub(/index.html$/, "")
    end

    def render_section(sitemap)
      template = ERB.new(File.read(File.join($options["root"], "_support/sitemap.entries.erb")))
      template.result(binding)
    end

    def generate()
      puts "[S] Generating sitemap..."

      template = ERB.new(File.read(File.join($options["root"], "_support/sitemap.erb")))
      contents = template.result(binding)

      Page.from_string(
        contents,
        root_relative: "",
        page: "sitemap.html",
        out_path: File.join($options["output_dir"], "sitemap.html"),
      )
        .make_page()
    end
  end

  # A sitemap entry.
  # Composed of an output path and its document.
  # Generally speaking, the `#catalog` is used to get the sections.
  class Sitemap::Entry
    attr_reader :path
    attr_reader :doc
    attr_reader :catalog
    attr_accessor :entries

    def sitemap_index?()
      !!doc.attributes["sitemap_index"]
    end

    def initialize(path, doc)
      @path = path
      @doc = doc
      @entries = []

      @catalog =
        if @doc.attributes["sitemap_index"]
          []
        else
          @doc.sections.select { |sect| sect.id }.map do |section|
            [section.id, section.title]
          end
        end

      @catalog.insert(0, ["", @doc.attributes["doctitle"] || @doc.doctitle])
    end
  end
end
