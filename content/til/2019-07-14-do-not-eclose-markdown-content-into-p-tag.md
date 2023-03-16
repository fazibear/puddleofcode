---
section: til
date: 2019-07-14
slug: do-not-eclose-markdown-content-into-p-tag
title: Do Not Eclose Markdown Content Into <p> Tag
author: Michał Kalbarczyk
author_image: ../images/authors/michal.png
---

If you are using for example Gatsby like I do, don't enlose html from markdown into `<p>` tag.
The content of `<p>` will be missing in some cases.
Anyway`<p>` should not include any block elements such as `<p>`.

Instead of:

```html
<p className="article-post" dangerouslySetInnerHTML={{ __html: html }} />
```

use:

```html
<div className="article-post" dangerouslySetInnerHTML={{ __html: html }} />
```
