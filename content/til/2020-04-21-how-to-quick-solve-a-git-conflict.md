---
section: til
date: 2020-04-21
slug: how-to-quick-solve-a-git-conflict
title: How to Quick Solve a Git Conflict? 
author: Michał Kalbarczyk
author_image: ../images/authors/michal.png
---
When you are in the conflct state simply type:

```sh
# git checkout --ours .
# git add .
```

to keep all your changes, or:

```sh
# git checkout --theirs .
# git add .
```

to do the opposite.

