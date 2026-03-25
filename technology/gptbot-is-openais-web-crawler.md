---
title: "GPTBot is OpenAI’s web crawler "
date: "2025-02-26"
tags: []
---

OpenAI's web crawler has a user-agent:

```
User agent token: GPTBot
Full user-agent string: Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; GPTBot/1.0; +https://openai.com/gptbot)
```

Which means it can be restricted to crawl your site using robots.txt:

```
User-agent: GPTBot
Disallow: /
```

Found in OpenAI's [documentation](https://platform.openai.com/docs/gptbot).
