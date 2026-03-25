---
title: "Use same git commit message as previous commit"
date: "2025-03-26"
tags: []
---

```bash
git commit --reuse-message HEAD
```

`--reuse-message` takes an existing commit and reuse the log message.

Add `--edit` to bring up the editor if you wish to edit the message before committing.
