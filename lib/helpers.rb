module Nanoc::Helpers
  module My
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
      date.strftime("%-d %B %Y")
    end
  end
end

use_helper Nanoc::Helpers::Rendering
use_helper Nanoc::Helpers::LinkTo
use_helper Nanoc::Helpers::Text
use_helper Nanoc::Helpers::My
