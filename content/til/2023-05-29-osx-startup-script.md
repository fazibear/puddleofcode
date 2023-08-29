---
date: 2023-05-29
title: How to create custom OSX startup script?
---

If you wondering how you can create a script that lunch things on startup?

Create a file `~/Library/LaunchAgents/com.user.startup.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.user.startup</string>
    <key>ProgramArguments</key>
    <array>
      <string>sh</string>
      <string>-c</string>
      <string>"$HOME/.config/startup.sh"</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
  </dict>
</plist>
```

And your script file `~/.config/startup.sh`:

```bash
#!/bin/bash

# run what you want
```

Run `launchctl load -w ~/Library/LaunchAgents/com.user.startup.plist`

That's it!
