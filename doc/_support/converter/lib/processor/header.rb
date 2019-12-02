module Processor
  class Header
    attr_reader :page
    attr_reader :root_relative

    def initialize(page, root_relative)
      @page = page
      @root_relative = root_relative
    end

    def link(q, label)
      [
        "<a href='#{root_relative + q}' class='#{if q == page then "is-active" end}'>",
          label,
          "</a>",
      ].join("")
    end

    def header()
      header = ERB.new(File.read(File.join($options["root"], "_support/header.erb")))
      rootrel = root_relative
      header.result(binding)
    end

    def append_header(document)
      output = document.split("\n")
      idx = output.find_index do |line|
        line.match(/<body /)
      end
      output.insert(idx+1, header)
      output.join("\n")
    end
  end
end
