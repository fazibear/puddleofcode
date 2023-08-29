---
date: 2019-12-31
title: Can't Compile Rust Code to asmjs/wasm
---

When following error brakes your compilation to asmjs/wasm:

```bash
 = note: shared:ERROR: fastcomp is not compatible with wasm object ...
```

Just update emstcripten, and install upstream compiler.

```bash
$ emsdk install latest-upstream
$ emsdk activate latest-upstream
```

