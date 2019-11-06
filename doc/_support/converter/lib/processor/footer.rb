module Processor
  class Footer
    attr_reader :page
    attr_reader :root_relative

    def initialize(doc, page, root_relative, source_file: nil)
      @doc = doc
      @page = page
      @root_relative = root_relative
      @source_file = source_file
    end

    def link(q, label)
      [
        "<a href='#{root_relative + q}' class='#{if q == page then "is-active" end}'>",
        label,
        "</a>",
      ].join("")
    end

    def src()
      if @doc.attributes["relative_file_path"] then
        @doc.attributes["relative_file_path"]
      else
        "doc/#{@source_file}"
      end
    end

    def github_edit_link(label)
      [
        "<a href='https://github.com/NixOS/mobile-nixos/edit/master/#{src}'>",
        label,
        "</a>",
      ].join("")
    end

    def github_source_link(label)
      [
        "<a href='https://github.com/NixOS/mobile-nixos/blob/master/#{src}'>",
        label,
        "</a>",
      ].join("")
    end

    def generated?()
      !@source_file || !!@doc.attributes["generated"]
    end

    def append_footer(document)
      footer = ERB.new(File.read(File.join($options["root"], "_support/footer.erb")))
      rootrel = root_relative

      footer = footer.result(binding)

      output = document.split("\n")
      idx = output.find_index do |line|
        line.match(/<\/body>/)
      end
      output.insert(idx, footer)
      output.join("\n")
    end
  end
end
