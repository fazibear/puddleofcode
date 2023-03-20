module Nanoc::Helpers
  module Pagination
    def add_pagination_for(source, destination, per_page)
      pages = @items
        .find_all(source)
        .map {|item| item.identifier}
        .reverse
        .each_slice(per_page)

      pages_links = pages.with_index.map do |item, index|
        [index, destination + (index > 0 ? "/#{index}" : "")]
      end

      pages.with_index.each do |items, index|
          identifier = destination + (index > 0 ? "/#{index}" : "")
          @items.create('', {items: items, page: index, pages: pages_links}, identifier)
      end
    end
  end
end

use_helper Nanoc::Helpers::Pagination
