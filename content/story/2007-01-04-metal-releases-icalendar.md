---
date: 2007-01-04
slug: metal-releases-icalendar
title: Metal Releases ICalendar
tags:
  - ruby
  - music

section: story
image: /assets/images/stories/archived.jpg
author: Michał Kalbarczyk
author_image: ../images/authors/michal.png
---

This simple ruby script parse [http://www.metalstorm.ee/](http://www.metalstorm.ee/) and create ical file with new and upcoming releases.

<del>You can find it [here](http://fazibear.xmgfree.com/scripts/metalstorm-releases.cgi).<br />If you want to see it in action, click [here](http://www.google.com/calendar/embed?src=cv176ji4gaam7c3hbg391cdbct14o9ji%40import.calendar.google.com").</del>

Because of hosting problem, script is unavailable, but check new version [here](http://metalstorm-releases.appjet.net/calendar.ics).

Here is whole cgi script:

```ruby
require 'rubygems'
require 'net/http'
require 'cgi'

puts "Content-Type: text/plain"
puts

puts "BEGIN:VCALENDAR"
puts "VERSION:2.0"
puts "PRODID:-//hacksw/handcal//NONSGML v1.0//EN"
puts "X-WR-CALNAME:Metal Storm Releases"
>puts "X-WR-CALDESC:New and Upcomming Music Metal Releases taken from http://www.metalstorm.ee. Made by FaziBear."
new = Net::HTTP.get_response( URI.parse('http://www.metalstorm.ee/events/new_releases.php'))
upc = Net::HTTP.get_response( URI.parse('http://www.metalstorm.ee/events/new_releases.php?upcoming=1'))

text = ""
text << new.body
text << upc.body

year = 0;

text.scan(/<span class=title>.*?(\d\d\d\d).*?<\/span><br>|<br><span class=dark>(\d\d).(\d\d).*?<\/span><a href=#(.*?)>(.*?)<\/a>/i) do |is_year, day,month, id ,desc|
  if (! is_year.nil?) then<
    #puts "|#{is_year}|#{day}|#{month}|#{id}|#{desc}"
    year = is_year
  else
    puts "BEGIN:VEVENT"
    puts "DTSTART:#{year}#{month}#{day}"
    puts "DTEND:#{year}#{month}#{day}"
    puts "SUMMARY:#{CGI::unescapeHTML(desc)}"
    puts "URL:http://www.metalstorm.ee/events/new_releases.php##{id}"
    puts "END:VEVENT"
    end
end

puts "END:VCALENDAR"
```
