---
date: 2023-03-20
title: Best dotfiles manager is GIT
tags:
  - git
  - symlink
  - dotfiles
image: /images/stories/symlink.jpg
---

Long story short. Tried lot of dotfiles managers including custom solutions. All of them have a big disadvantage. You have a copy of a file or symlink.
What do we need? Just git. Let's start!

First of all we need a shell alias to manage our files.

I'm using fish so creating alias looks like this.

```bash
$ alias hi "echo hello"
```

But you can do same thing in bash as well:

```bash
$ alias hi="echo hello"
```

Let's name our alias `dot`.

Just add such a line in your shell config file.

Depending on our needs we can:

Allow to backup files on whole disk:

```bash
alias dot "git --git-dir=$HOME/.dotfiles --work-tree=/"
```

Or just in the home directory:

```bash
alias dot "git --git-dir=$HOME/.dotfiles --work-tree=$HOME"
```

Great. We're just made an dot manager!

Let's init out repo

```bash
$ dot init
```

One more thing! Need to set up one thing:

```bash
$ dot config --local status.showUntrackedFiles no
```

And we're done. All git files are in `$HOME/.dotfiles` directory.

To add a file or directory we can simply:

```bash
$ dot add ~/.config
```

and commit it with

```bash
$ dot commit
```

The backup is a `git` repository. We can push it to github for example. Just add remote like on every other git repository.

Just like you saw. There is no copying, linking, just adding a files when something changed.
