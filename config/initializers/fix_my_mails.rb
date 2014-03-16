module ActionView
  class Template
    module Handlers
      class ERB
        class_attribute :escape_whitelist
        self.escape_whitelist = ["text/plain", "text/rtf"]
        def compile(template)
          if template.source.encoding_aware?
            # First, convert to BINARY, so in case the encoding is
            # wrong, we can still find an encoding tag
            # (<%# encoding %>) inside the String using a regular
            # expression
            template_source = template.source.dup.force_encoding("BINARY")

            erb = template_source.gsub(ENCODING_TAG, '')
            encoding = $2

            erb.force_encoding valid_encoding(template.source.dup, encoding)

            # Always make sure we return a String in the default_internal
            erb.encode!
          else
            erb = template.source.dup
          end

          self.class.erb_implementation.new(
            erb,
            :trim => (self.class.erb_trim_mode == "-"),
            :escape => (self.class.escape_whitelist.include? template.mime_type) # only escape HTML templates
          ).src
        end
      end
    end
  end
end
