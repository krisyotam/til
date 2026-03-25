---
title: "Get last modified date using GitHub GraphQL API"
date: "2025-03-23"
tags: []
---

Query the first item in the history of that path and return the `committedDate`:

```graphql
query CommittedDate($name: String!, $owner: String!, $path: String!) {
  repository(owner: $owner, name: $name) {
    ref(qualifiedName: "refs/heads/master") {
      target {
        ... on Commit {
          history(first: 1, path: $path) {
            edges {
              node {
                committedDate
              }
            }
          }
        }
      }
    }
  }
}
```
