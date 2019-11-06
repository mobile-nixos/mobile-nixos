module Processor
  class TOC
    def initialize(doc)
      toc = doc.converter.convert(doc, "outline")
      @toc =
        if toc then
          "<div id='toc'>#{toc}</div>"
        else
          nil
        end
    end

    def insert_toc(document)
      if @toc then
        output = document.split("\n")
        idx = output.find_index do |line|
          line.match(/<div id="content/)
        end
        output.insert(idx, @toc)
        output
          .join("\n")
          .sub(/<body class="/, '<body class="with-toc ')
      else
        document
      end
    end
  end
end

