---
date: 2008-01-03
title: CodePress Addons
tags:
  - javascript
  - codepress
  - rails

image: /assets/images/stories/archived.jpg
---

I was playing around with CodePress. There are some modification I made:
This one updates all textareas fields when form is submited, and fix the problem with rails javascript tag hepler.

```js
CodePress.run = function() {
  s = document.getElementsByTagName('script');
  for(var i=0,n=s.length;i<n;i++) {
    if(s[i].src.match('codepress.js')) {
      CodePress.path = s[i].src.replace(/codepress.js.*$/,'');
    }
  }
  t = document.getElementsByTagName('textarea');
  for(var i=0,n=t.length;i<n;i++) {
    if(t[i].className.match('codepress')) {
      id = t[i].id;
      t[i].id = id+'_cp';
      eval(id+' = new CodePress(t[i])');
      t[i].parentNode.insertBefore(eval(id), t[i]);
    }
  }
  f = document.getElementsByTagName('form');
  for(var i=0,n=f.length;i<n;i++) {
    cps = f[i].getElementsByClassName('codepress');
    if(cps.length > 0){
      f[i].cps = cps;
      f[i].onsubmit = function(){
        for(var i=0;i<this.cps.length;i++){
          this.cps[i].value = eval(this.cps[i].id.replace('_cp','')+'.getCode()');
          this.cps[i].disabled = false;
        };
      }
    }
  }
}
```

I've also updated the syntax highlight for the Ruby language:

```js
/*
* CodePress regular expressions for Ruby syntax highlighting
*/
// Ruby
Language.syntax = [
  { input : /\"(.*?)(\"|<br>|<\/P>)/g, output : '<s>"$1$2</s>' }, // strings double quote
  { input : /\'(.*?)(\'|<br>|<\/P>)/g, output : '<s>\'$1$2</s>' }, // strings single quote
  { input : /([\$\@\%]+)([\w\.]*)/g, output : '<a>$1$2</a>' }, // vars
  { input : /\|(.*?)(\||<br>|<\/P>)/g, output : '|<a>$1</a>$2' }, // block vars
  { input : /(def\s+)([\w\.]*)/g, output : '$1<em>$2</em>' }, // functions
  { input : /\b(alias|and|BEGIN|begin|break|case|class|def|defined|do|else|elsif|END|end|ensure|false|for|if|in|module|next|nil|not|or|redo|rescue|retry|return|self|super|then|true|undef|unless|until|when|while|yield)\b/g, output : '<b>$1</b>' }, // reserved words
  { input  : /([\(\){}])/g, output : '<u>$1</u>' }, // special chars
  { input  : /#(.*?)(<br>|<\/P>)/g, output : '<i>#$1</i>$2' }, // comments
  { input  : /#(.*?)(<br>|<\/P>)/g, output : '<i>#$1</i>$2' }, // comments
  { input  : /\b(Array|Bignum|Binding|Class|Continuation|Dir|Exception|FalseClass|File|Fixnum|Fload|Hash|Integer|IO|MatchData|Method|Module|NilClass|Numeric|Object|Proc|Range|Regexp|String|Symbol|ThreadGroup|Thread|Time|TrueClass)\b/g, output : '<big>$1</big>' } // buildins
];
Language.snippets = []
Language.complete = [
  { input : '\'',output : '\'$0\'' },
  { input : '"', output : '"$0"' },
  { input : '(', output : '\($0\)' },
  { input : '[', output : '\[$0\]' },
  { input : '{', output : '{$0}' }
]
Language.shortcuts = []
```
