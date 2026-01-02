If you have implemented a custom command(s) that you find useful, please add it here so others can find it too. If a particular command proves popular, we will merge it into the codebase for all to use.

If you want to know how to implement your own custom commands see [here](https://github.com/jesseduffield/lazygit/blob/master/docs/Custom_Command_Keybindings.md)

## Comparing a file in a previous revision with the working copy

When navigating the commits, select a file, and press 'f' to compare it with the git difftool against the working copy.

Does not work with renamed files though.

```yml
customCommands:
  - key: 'f'
    command: "git difftool -y {{.SelectedLocalCommit.Sha}} -- {{.SelectedCommitFile.Name}}"
    context: 'commitFiles'
    description: 'Compare (difftool) with local copy'
```

## Creating a review in [Gerrit](https://gerrit-review.googlesource.com/Documentation/intro-gerrit-walkthrough.html)

```yml
customCommands:
  - key: '<c-p>'
    command: "git push origin HEAD:refs/for/{{.CheckedOutBranch.Name}}"
    context: 'global'
    loadingText: 'pushing'
```

## Pushing to a specific remote repository

This custom command allows picking between already used remote repositories and pushing with force and/or with lease.
```yml
  - key: '<c-P>'
    description: "Push to a specific remote repository"
    context: 'global'
    loadingText: 'Pushing ...'
    prompts:
      - type: 'menuFromCommand'
        title: 'Which remote repository to push to?'
        command: bash -c "git remote --verbose | grep '/.* (push)'"
        filter: '(?P<remote>.*)\s+(?P<url>.*) \(push\)'
        valueFormat: '{{ .remote }}'
        labelFormat: '{{ .remote | bold | cyan }} {{ .url }}'
      - type: 'menu'
        title: 'How to push?'
        options:
          - value: 'push'
          - value: 'push --force-with-lease'
          - value: 'push --force'
    command: "git {{index .PromptResponses 1}} {{index .PromptResponses 0}}"

```

## Pushing to a specific remote branch

```yml
customCommands:
  - key: '<c-p>'
    context: 'global'
    loadingText: 'pushing'
    prompts:
      - type: 'input'
        title: 'which branch do you want to push to?'
    command: "git push origin {{index .PromptResponses 0}}"
```

## Pushing a specific commit

Pushes a specific commit, and any preceding commits. Useful if you're still working on the latest commit but you have earlier commits ready to push.

```yml
customCommands:
  - key: 'P'
    command: "git push {{.SelectedRemote.Name}} {{.SelectedLocalCommit.Sha}}:{{.SelectedLocalBranch.Name}}"
    context: "commits"
    loadingText: "Pushing commit..."
    description: "Push a specific commit (and any preceding)"
    stream: yes
```

## Open Existing Github Pull Request in Browser

In the branches panel, opens the PR for the selected branch; in the commits panel, opens the PR for the currently checked out branch.

```yml
customCommands:
  - key: "G"
    command: "gh pr view -w {{.SelectedLocalBranch.Name}}"
    context: "localBranches"
    description: "Open Github PR in browser"
  - key: "G"
    command: "gh pr view -w"
    context: "commits"
    description: "Open Github PR in browser"
```

## Open Existing GitLab Pull Request in Browser

```yml
customCommands:
  - key: "G"
    command: "glab mr view -w {{.SelectedLocalBranch.UpstreamBranch}}"
    context: "localBranches"
    description: "Go to MR in gitlab"
    stream: true
```

Note: this can be updated to go to github by replacing the command with something similar to the above "Open GitHub Pull Request"

## Checkout branch via Github Pull Request id

```yml
customCommands:
  - key: "v" # couldn't think of a better keybinding
    prompts:
      - type: 'input'
        title: 'PR id:'
    command: "hub pr checkout {{index .PromptResponses 0}}"
    context: "localBranches"
    loadingText: "checking out PR"
```

## List and Select GitHub PR for Checkout

```yml
customCommands:
  - key: "v"
    context: "localBranches"
    loadingText: "Checking out GitHub Pull Request..."
    command: "gh pr checkout {{.Form.PullRequestNumber}}"
    prompts:
      - type: "menuFromCommand"
        title: "Which PR do you want to check out?"
        key: "PullRequestNumber"
        command: >-
          gh pr list --json number,title,headRefName,updatedAt
          --template '{{`{{range .}}{{printf "#%v: %s - %s (%s)" .number .title .headRefName (timeago .updatedAt)}}{{end}}`}}'
        filter: '#(?P<number>[0-9]+): (?P<title>.+) - (?P<ref_name>[^ ]+).*'
        valueFormat: '{{.number}}'
        labelFormat: '{{"#" | black | bold}}{{.number | white | bold}} {{.title | yellow | bold}}{{" [" | black | bold}}{{.ref_name | green}}{{"]" | black | bold}}'
```

## Opening git mergetool

```yml
customCommands:
  - key: "M"
    command: "git mergetool {{ .SelectedFile.Name }}"
    context: "files"
    loadingText: "opening git mergetool"
    subprocess: true
```

## Pruning deleted remote branches

```yml
customCommands:
  - key: "<c-p>"
    command: "git remote prune {{.SelectedRemote.Name}}"
    context: "remotes"
    loadingText: "Pruning..."
    description: "prune deleted remote branches"
```

## Pruning merged local branches

```yml
customCommands:
  - key: "b"
    command: "git branch --merged master | grep -v '^[ *]*master$' | xargs -r git branch -d"
    context: "localBranches"
    loadingText: "Pruning..."
    description: "prune local branches that have been merged to master"
```

## Pruning branches no longer on the remote.

Implementation inspiration [here on Stackoverflow](https://stackoverflow.com/a/33548037/2081835). Basically, delete all the branches displaying `(upstream gone)`.

```yml
customCommands:
  - key: "G"
    command: |
      git fetch -p && for branch in $(git for-each-ref --format '%(refname) %(upstream:track)' refs/heads | awk '$2 == "[gone]" {sub("refs/heads/", "", $1); print $1}'); do git branch -D $branch; done
    context: "localBranches"
    description: "Prune local branches no longer on its remote; (G)one."
    loadingText: "Pruning gone..."
```

## committing via [Commitizen](https://commitizen-tools.github.io/commitizen/) (`cz c`)

```yml
customCommands:
  - key: "C"
    command: "git cz c"
    description: "commit with commitizen"
    context: "files"
    loadingText: "opening commitizen commit tool"
    subprocess: true
```

## Searching the repo's history for a word appearing in a specified subtree

> You need to build lazygit from master branch for this to work!

```yml
customCommands:
  - key : '<c-a>'
    description: 'Search the whole history (From a ref and down) for an expression in a file'
    command: "git checkout {{index .PromptResponses 3}}"
    context: 'commits'
    prompts:
      - type: 'input'
        title: 'Search word:'
      - type: 'input'
        title: 'File/Subtree:'
      - type: 'input'
        title: 'Ref:'
        initialValue: "{{index .CheckedOutBranch.Name }}"
      - type: 'menuFromCommand'
        title: 'Commits:'
        command: "git log --oneline {{index .PromptResponses 2}} -S'{{index .PromptResponses 0}}' --all -- {{index .PromptResponses 1}}"
        filter: '(?P<commit_id>[0-9a-zA-Z]*) *(?P<commit_msg>.*)'
        valueFormat: '{{ .commit_id }}'
        labelFormat: '{{ .commit_id | green | bold }} - {{ .commit_msg | yellow }}'
```

Example Usage on lazygit repo:
 - Search word: `lazygit`
 - Subtree/File: `**/commits.go`
 - Ref: `master`
Note also that color functions are supported in `labelFormat`

## Fetch a remote branch as a new local branch

```yml
customCommands:
  - key: '<c-f>'
    description: 'fetch a remote branch as a new local branch'
    command: "git fetch {{index .SelectedRemote.Name }} {{index .PromptResponses 0}}:{{index .PromptResponses 1}}"
    context: 'remotes'
    prompts:
      - type: 'input'
        title: 'Remote Branch Name'
        initialValue: ''
      - type: 'input'
        title: 'New Local Branch Name'
        initialValue: ''
    loadingText: 'fetching branch'
```

## Commit as non-default author

```yml
customCommands:
  - key: '<c-c>'
    description: 'commit as non-default author'
    command: 'git commit -m "{{index .PromptResponses 0}}" --author="{{index .PromptResponses 1}} <{{index .PromptResponses 2}}>"'
    context: 'files'
    prompts:
      - type: 'input'
        title: 'Commit Message'
        initialValue: ''
      - type: 'input'
        title: 'Author Name'
        initialValue: ''
      - type: 'input'
        title: 'Email Address'
        initialValue: ''
    loadingText: 'commiting'
```

## Amend the author of last commit

```yml
customCommands:
  - key: '<c-a>'
    description: 'amend the author of last commit'
    command: 'git commit --amend --author="{{index .PromptResponses 0}} <{{index .PromptResponses 1}}>"'
    context: 'commits'
    prompts:
      - type: 'input'
        title: 'Author Name'
        initialValue: ''
      - type: 'input'
        title: 'Email Address'
    subprocess: yes

        initialValue: ''
    subprocess: true
```

## Blame via [tig](https://jonas.github.io/tig/)
```yml
customCommands:
  - key: b
    command: tig blame -- {{.SelectedFile.Name}}
    context: files
    description: blame file at tree
    subprocess: yes
  - key: b
    command: tig blame {{.SelectedSubCommit.Sha}} -- {{.SelectedCommitFile.Name}}
    context: commitFiles
    description: blame file at revision
    subprocess: yes
  - key: B
    command: tig blame -- {{.SelectedCommitFile.Name}}
    context: commitFiles
    description: blame file at tree
    subprocess: yes
```
## Browse files at revision via [tig](https://jonas.github.io/tig/)
```yml
customCommands:
  - key: t
    command: tig show {{.SelectedSubCommit.Sha}}
    context: subCommits
    description: tig commit (`t` again to browse files at revision)
    subprocess: yes
  - key: t
    command: tig show {{.SelectedLocalBranch.Name}}
    context: localBranches
    description: tig branch (`t` again to browse files at revision)
    subprocess: yes
  - key: t
    command: tig show {{.SelectedRemoteBranch.RemoteName}}/{{.SelectedRemoteBranch.Name}}
    context: remoteBranches
    description: tig branch (`t` again to browse files at revision)
    subprocess: yes
```
## File history via [tig](https://jonas.github.io/tig/)
```yml
customCommands:
  - key: t
    command: tig {{.SelectedSubCommit.Sha}} -- {{.SelectedCommitFile.Name}}
    context: commitFiles
    description: tig file (history of commits affecting file)
    subprocess: yes
  - key: t
    command: tig -- {{.SelectedFile.Name}}
    context: files
    description: tig file (history of commits affecting file)
    subprocess: yes
```

## Extract diff into index

This requires some explanation: say you've got a PR that has merged in master a few times and so it's a bit of a mess to follow the changes, but there's actually not that many lines changed in total. In that case, you probably just want to take the actual changes and put them in a single commit on top of the head of the master branch.

```yml
customCommands:
  - key: 'D'
    command: git diff {{.SelectedLocalBranch.Name}} > /tmp/lazygit.patch && git reset --hard {{.SelectedLocalBranch.Name}} && git apply /tmp/lazygit.patch 
    context: localBranches
    description: Extract diff into index
```

## Add empty commit

```yml
  - key: 'E'
    description: 'Add empty commit'
    context: 'commits'
    command: 'git commit --allow-empty -m "empty commit"'
    loadingText: 'Committing empty commit...'
```

## Pull from specific remote

```yml
  - key: '<c-p>'
    description: "Pull from a specific remote repository"
    context: 'files'
    loadingText: 'Pulling ...'
    command: git pull {{ .Form.Remote }} {{ .Form.RemoteBranch }}
    prompts:
      - type: 'input'
        key: 'Remote'
        title: "Remote:"
        suggestions:
          preset: 'remotes'
      - type: 'input'
        key: 'RemoteBranch'
        title: "Remote branch:"
        suggestions:
          command: "git branch --remote --list '{{.Form.Remote}}/*' --format='%(refname:short)' | sed 's/{{.Form.Remote}}\\///'"
```

## Conventional commit

Prompts to follow the [conventional commits](https://www.conventionalcommits.org/) pattern.

```yaml
customCommands:
  # retrieved from: https://github.com/jesseduffield/lazygit/wiki/Custom-Commands-Compendium#conventional-commit
  - key: "<c-v>"
    context: "global"
    description: "Create new conventional commit"
    prompts:
      - type: "menu"
        key: "Type"
        title: "Type of change"
        options:
          - name: "build"
            description: "Changes that affect the build system or external dependencies"
            value: "build"
          - name: "feat"
            description: "A new feature"
            value: "feat"
          - name: "fix"
            description: "A bug fix"
            value: "fix"
          - name: "chore"
            description: "Other changes that don't modify src or test files"
            value: "chore"
          - name: "ci"
            description: "Changes to CI configuration files and scripts"
            value: "ci"
          - name: "docs"
            description: "Documentation only changes"
            value: "docs"
          - name: "perf"
            description: "A code change that improves performance"
            value: "perf"
          - name: "refactor"
            description: "A code change that neither fixes a bug nor adds a feature"
            value: "refactor"
          - name: "revert"
            description: "Reverts a previous commit"
            value: "revert"
          - name: "style"
            description: "Changes that do not affect the meaning of the code"
            value: "style"
          - name: "test"
            description: "Adding missing tests or correcting existing tests"
            value: "test"
      - type: "input"
        title: "Scope"
        key: "Scope"
        initialValue: ""
      - type: "menu"
        key: "Breaking"
        title: "Breaking change"
        options:
          - name: "no"
            value: ""
          - name: "yes"
            value: "!"
      - type: "input"
        title: "message"
        key: "Message"
        initialValue: ""
      - type: "confirm"
        key: "Confirm"
        title: "Commit"
        body: "Are you sure you want to commit?"
    command: "git commit --message '{{.Form.Type}}{{ if .Form.Scope }}({{ .Form.Scope }}){{ end }}{{.Form.Breaking}}: {{.Form.Message}}'"
    loadingText: "Creating conventional commit..."
```

## Disentangle branch

Often you'll have a branch which doesn't do much but has a bunch of messy merge commits from merging in the main branch. If you want to convert that to just a single commit, i.e. disentangle the branch, you can use this custom command:

```yaml
customCommands:
  - key: 'K'
    description: "Disentangle: Squash all changes into a single commit and rebase onto the selected branch"
    context: localBranches
    command: |
      #!/bin/bash

      # Set the base branch
      BASE_BRANCH="{{.SelectedLocalBranch.Name}}"

      # Check if the working tree is dirty
      if [[ -n $(git status --porcelain) ]]; then
          echo "Error: Working tree is dirty. Please commit or stash your changes before running this script."
          exit 1
      fi

      # Get the merge base commit
      merge_base=$(git merge-base $BASE_BRANCH HEAD)

      # Get the first commit hash, message, and author details
      first_commit_hash=$(git rev-list --reverse $merge_base..HEAD | head -n 1)
      first_commit_message=$(git log -1 --format=%B $first_commit_hash)

      # Reset to the merge base
      git reset $merge_base

      # Stage all changes
      git add -A

      # Create a new commit with all the changes, using the first commit's message and author
      GIT_AUTHOR_NAME="$(git log -1 --format='%an' $first_commit_hash)" \
      GIT_AUTHOR_EMAIL="$(git log -1 --format='%ae' $first_commit_hash)" \
      git commit -m "$first_commit_message"

      # Rebase onto the base branch
      git rebase $BASE_BRANCH
```

## Add Gitmojis to commit description

When you want to be able to select an emoji just like with gitmoji-cli but within lazygit (require gitmoji-cli installed)

```yaml
customCommands:
- command: git commit -m '{{ .Form.emoji }} {{ .Form.message }}'
  context: files
  description: Commit changes using gitmojis
  key: C
  prompts:
  - command: gitmoji -l
    filter: ^(.*?) - (:.*?:) - (.*)$
    key: emoji
    labelFormat: '{{ .group_1 }} - {{ .group_3 }}'
    title: 'Select a gitmoji:'
    type: menuFromCommand
    valueFormat: '{{ .group_2 }}'
  - key: message
    title: 'Enter a commit message:'
    type: input
```

gitmoji with scope field like conventional commits
```yaml
customCommands:
  - command: "git commit -m '{{ .Form.emoji }} {{ if .Form.scope }} ({{ .Form.scope }}): {{ end }} {{ .Form.message }}'"
    context: files
    description: Commit changes using gitmojis
    key: C
    prompts:
    - command: gitmoji -l
      filter: ^(.*?) - (:.*?:) - (.*)$
      key: emoji
      labelFormat: '{{ .group_1 }} - {{ .group_3 }}'
      title: 'Choose a gitmoji: '
      type: menuFromCommand
      valueFormat: '{{ .group_2 }}'
    - key: scope
      title: 'Enter the scope of current changes: '
      type: input
    - key: message
      title: 'Enter the commit title: '
      type: input
```