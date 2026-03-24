---
description: Git add changes and commit
agent: build
---

## Task

Your task is to add all your changes to git and commit them.

Please follow these instructions:
- DO only add the changes you made
- DO remember to also add files you created to git

For the commit follow these guidelines:
- DO use a good descriptive commit message
- If you have a ticket number you SHOULD include it into your commit message e.g. "<ticket number>: <change description>"
- Always DO remember to use "--no-gpg-sign" as parameter to avoid getting prompted for a password
- Always DO name yourself as coauthor of a commit

You can use other commands to get your changes:
- `git status`
- `git diff`

## Example workflow

1. Changed files:
  - `./foo/bar.txt`
  - `./foo/bar.md`
  - `./README.md`
  - `./package.json`

2. Add changes to git:
  - `git add ./foo/bar.txt ./foo/bar.md ./README.md ./package.json`
  - Check if added successfully using `git status`

3. Commit changes:
  - Following
```
git commit --no-gpg-sign -m "be-bla-foo-01: Add foo dir and adjust readme

Co-authored-by: OpenCode <bot@opencode.ai>"
```
  - Note: The co-author trailer needs to be separated from the message body by a blank line
