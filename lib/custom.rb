module Nanoc::Helpers
  module Custom
    def cannonical_path(item)
      "#{@config.dig(:base_url)}#{path(item).gsub('index.html', '')}"
    end

    def path(item)
      item.identifier.without_ext.match %r[/([^\/]+)/([0-9]+)\-([0-9]+)\-([0-9]+)\-([^\/]+)] do |match|
        return "/#{match[1]}/#{match[5]}/index.html"
      end

      if item.identifier =~ '/index.*'
        '/index.html'
      else
        item.identifier.without_ext + '/index.html'
      end
    end

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

    def remove_drafts
      @items.delete_if { |item| ENV["GITHUB_JOB"] && item[:draft] }
    end
  end
end

use_helper Nanoc::Helpers::Custom
