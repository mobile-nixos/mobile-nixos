module Processor
  class Base
    def load_adoc(contents, **options)
      Asciidoctor.load(
        contents,
        standalone: true,
        attributes: {
          "rootrel" => @root_relative,
        }.merge(styles_attributes),
        **DEFAULTS,
        **options,
      )
    end

    def styles_attributes()
      # Toggle default styles on if the builder is not given a stylesheet
      # directory to use.
      if $options["styles_dir"] then
        {
          "copycss" => true,
          "linkcss" => true,
          "stylesdir" =>
          if @root_relative == ""
            "styles"
          else
            File.join(@root_relative, "styles")
          end,
          "stylesheet" => "styles.css",
        }
      else
        {}
      end
    end

    def title()
      @doc.attributes["doctitle"] || @doc.doctitle
    end

    def date()
      Date.parse(@doc.revdate)
    end
  end
end
