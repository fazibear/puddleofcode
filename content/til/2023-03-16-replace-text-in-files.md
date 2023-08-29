---
date: 2023-03-16
title: How to replace text in files?
---

Wondering how you can replace text content in every file using regex?

Just create and alias using your shell. Im my case it will be fish alias:

Add to your `~/.config/fish/config.fish` this line:

```bash
alias replace "perl -p -i -e $argv"
```

and here you go!

```bash
~ $ replace 's/hello/goobye/g' *.md
```

BTW! Hope you have perl installed. I have ;)

