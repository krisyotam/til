---
title: "Accessing stdin with file descriptor 0"
date: "2025-05-02"
tags: []
---

In Node.js, you can access `stdin` using file descriptor 0 to take input stream:

```js
const fs = require("fs");
const data = fs.readFileSync(0, "utf-8");
```

This can be used on the Node.js CLI:

```bash
echo Peter Mekhaeil | node -p "fs.readFileSync(0, 'utf8').toLowerCase().replaceAll(' ','-')"
```
