---
date: 2015-04-23
title: Fishy prompt widgets
tags:
  - fish
  - widgets
  - prompt
crosspost_to_medium: true
medium_link: https://medium.com/@fazibear/59fd534869f0

image: /assets/images/stories/fish.png
---

Fish is a nice shell, its nice, lite, fast, and have a lot of features. One of them is `universal variables`. This variables are shared across sessions. This is very useful when I want to have a nice handy information in the prompt. We don't want to execute command every time thats prompt appears. Lets use them.

This is what I'm talking about!

![fish widgets](/assets/images/content/fish_widgets.png)

Widgets are refreshed in background, lets use `cron`. Write a little script that gather system information and set some variable that can be displayed in prompt.
Create a `~/.config/fish/functions/prompt_info_update.fish`

`_prompt_info_status_for` function takes 3 parameters:

- a name of widget
- how often we want to refresh widget
- command line

I've got one for you here it is:

```js
function _prompt_info_status_for
  set prompt_info_variable prompt_info_$argv[1]
  set prompt_info_interval $argv[2]
  set prompt_info_cmd $argv[3]

  function _prompt_info_status_current_time
    date "+%s"
  end

  function _eval
    set result (eval $argv[1])
    if test -n result
      echo $result
    else
      echo ''
    end
  end

  if set -q $prompt_info_variable
    if test (math (_prompt_info_status_current_time) - $$prompt_info_variable[1][2] ) -ge $prompt_info_interval
      set -U $prompt_info_variable[1][2] (_prompt_info_status_current_time)
      set -U $prompt_info_variable[1][1] (_eval $prompt_info_cmd)
    end
  else
    set -U $prompt_info_variable[1][2] (_prompt_info_status_current_time)
    set -U $prompt_info_variable[1][1] (_eval $prompt_info_cmd)
  end
  echo $$prompt_info_variable[1][1]
end
```

Great. Lets set some widgets!!! I'm on OSX, lets use emoji as icons. We create 5 widgets:

- battery status
- free disk space
- free memory
- number of outdated brew package (refreshed once a day)
- internet connection check

This is so simple too. Gather information first, and glue our propry variable. `prompt_info` this is a good name ;)
Use some conditional, we don't want brew icon when we up to date, and display nothing when there are internet connection.
Look, this is it:

```js
function prompt_info_update --description "Update system information in prompt"
  _prompt_info_status_for battery (math '60 * 1  * 1 ') 'pmset -g batt | egrep "([0-9]+\%).*" -o --colour=auto | cut -f1 -d";"'
  _prompt_info_status_for disk    (math '60 * 1  * 1 ') 'df -h / | tail -n1|  awk "{ gsub(/i/,\"\"); print \$4 }"'
  _prompt_info_status_for memory  (math '60 * 1  * 1 ') 'top -l1 -s0 -n1 | awk "/PhysMem/ {print \$6}"'
  _prompt_info_status_for brew    (math '60 * 60 * 24') 'brew update > /dev/null; brew outdated | wc -l | tr -d "[[:space:]]"'
  _prompt_info_status_for ping    (math '60 * 1  * 1 ') 'ping -c1 google.com > /dev/null ; and echo "OK"'

  set -U prompt_info ""

  if test -n $prompt_info_battery[1]
    set -U prompt_info "$prompt_info🔋 $prompt_info_battery[1] "
  end

  set -U prompt_info "$prompt_info📚 $prompt_info_memory[1] 💾 $prompt_info_disk[1] "

  if test $prompt_info_brew[1] -gt 0
    set -U prompt_info "$prompt_info🍺 $prompt_info_brew[1] "
  end

  if not test -n $prompt_info_ping[1]
    set -U prompt_info "$prompt_info🚫  "
  end
end
```

Lets display in the right prompt.

```js
function fish_right_prompt
  echo $prompt_info
end
```

At the end, we need add something that updates our widgets.

```bash
$ crontab -e
```

and add

```bash
* * * * * /usr/local/bin/fish -c 'prompt_info_update'
```

And voila. Nice handy prompt widgets with about `50 LOC`
Another great stuff, quick and useful.

Cheers.
