module Processor
  class Head
    attr_reader :page
    attr_reader :root_relative

    def initialize(page, root_relative)
      @page = page
      @root_relative = root_relative
    end

    def head()
      [
        # Not producing RSS for now.
        # '<link lang="en" rel="alternate" type="application/rss+xml" title="RSS feed (EN)" href="',
        # "#{root_relative}index.xml",
        # '" />',
      ].join("")
    end

    def append_to_head(document)
      output = document.split("\n")
      idx = output.find_index do |line|
        line.match(/<\/head>/)
      end
      output.insert(idx, head)
      output.join("\n")
    end
  end
end
