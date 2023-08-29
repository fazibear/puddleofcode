---
date: 2020-04-21
title: How to Quick Solve a Git Conflict? 
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

