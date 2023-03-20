module Nanoc::Helpers
  module SpellChecker
    require 'spellchecker'
    require 'nokogiri'

    def spellcheck(ext)
      @items.each do |item|
        if item.identifier.ext.to_s == "md" && !item.binary? && !item.compiled_content.empty?
          doc = Nokogiri::HTML(item.compiled_content)
          doc.search('code').each do |src|
            src.remove
          end
          errors = ::Spellchecker.check(strip_html(doc.to_html))
          if errors.any?
            puts "#{item.identifier}"
            errors.each do |error|
              puts " - [#{error.type}] #{error.text} -> #{error.correction}"
            end
            puts
          end
        end
      end
    end
  end
end

use_helper Nanoc::Helpers::SpellChecker
