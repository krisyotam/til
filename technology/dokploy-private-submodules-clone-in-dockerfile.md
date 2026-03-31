---
title: "Dokploy fails on private Git submodules — clone in the Dockerfile instead"
date: "2026-03-30"
tags: ["dokploy", "docker", "git", "submodules"]
---

Dokploy automatically runs `git submodule update --init` after cloning your repo. If a submodule points to a private repository, this fails because Dokploy's internal git client has no credentials for it:

```
Submodule 'content/notes' (https://github.com/user/private-repo.git) registered for path 'content/notes'
Cloning into '/etc/dokploy/applications/.../content/notes'...
fatal: could not read Username for 'https://github.com': No such device or address
```

The fix is two steps. First, remove the submodule from Git so Dokploy never tries to clone it:

```bash
git rm -f content/notes
rm .gitmodules
rm -rf .git/modules/content
echo "content/notes" >> .gitignore
git commit -m "remove private submodule"
```

Then clone it in your Dockerfile using a build-time token:

```dockerfile
ARG GITHUB_TOKEN

COPY . .

RUN if [ -n "$GITHUB_TOKEN" ]; then \
      rm -rf content/notes && \
      git clone "https://oauth2:${GITHUB_TOKEN}@github.com/user/private-repo.git" content/notes; \
    fi
```

Pass `GITHUB_TOKEN` as a build argument in Dokploy. For local dev, use a symlink (`ln -s ~/notes content/notes`) which is gitignored.
