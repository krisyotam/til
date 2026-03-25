---
title: "CSS pseudo-classes and pseudo-elements"
date: "2025-03-09"
tags:
  - Art
---

[Pseudo-classes](https://developer.mozilla.org/en-US/docs/Web/CSS/Pseudo-classes) are states applied to the selected elements. They have a single colon (`:`).

```css
button:hover {
  background: red;
}
```

[Pseudo-elements](https://developer.mozilla.org/en-US/docs/Web/CSS/Pseudo-elements) selects specific parts of the selected elements. They have double colons (`::`).

```css
p::first-line {
  text-transform: uppercase;
}
```
