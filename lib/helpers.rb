module Nanoc::Helpers
  module Pagination
    def add_pagination_for(source, destination, per_page)
      @items
        .find_all(source)
        .map {|story| story.identifier}
        .reverse.each_slice(per_page)
        .each_with_index do |stories, index|
          identifier = destination + (index > 0 ? "/#{index}" : "")
          @items.create('', {stories: stories, page: index}, identifier)
      end
    end
  end
  module Other
    def preview(string, length: 25, omission: '...')
      strip_html(string)
        .split(' ')
        .take(length)
        .join(' ')
        .+(omission)
    end

    def ttr(string, label: ' minutes read')
      strip_html(string)
        .split(' ')
        .count
        ./(200)
        .round()
        .to_s()
        .+(label)
    end

    def human_date(date)
      (date.is_a?(Date) ? date : Date.parse(date)).strftime("%-d %B %Y")
    end
  end
end

use_helper Nanoc::Helpers::Rendering
use_helper Nanoc::Helpers::LinkTo
use_helper Nanoc::Helpers::Text
use_helper Nanoc::Helpers::Other
use_helper Nanoc::Helpers::Pagination
