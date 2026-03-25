---
title: "Remove debugger statements in Vite"
date: "2025-06-15"
tags:
  - Programming
---

We can use esbuild's [drop](https://esbuild.github.io/api/#drop) option to remove `console` APIs and `debugger` statements from our code when we build our application.

```js
export default defineConfig({
    esbuild: {
      drop: ['console', 'debugger']
    }
});
```
