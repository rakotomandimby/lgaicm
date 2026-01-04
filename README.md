# `lgaicm` - LazyGit AI Commit Message

**Generate AI-powered conventional commit messages directly in LazyGit.** Press a hotkey, select a commit type, choose from AI-generated suggestions, and commit—all without leaving LazyGit.

## Quick Start

### What You Need
- [LazyGit](https://github.com/jesseduffield/lazygit) installed
- OpenAI API key
- `bash`, `git`, `curl`, and `jq`

### Setup in 3 Steps

**1. Install `lgaicm`:**
```bash
git clone https://github.com/rakotomandimby/lgaicm.git
cd lgaicm
chmod +x lgaicm
ln -s "$(pwd)/lgaicm" /usr/local/bin/lgaicm
```

**2. Set your OpenAI API key:**
```bash
export OPENAI_API_KEY="your-openai-api-key-here"
# Add to ~/.bashrc or ~/.zshrc for persistence
```

**3. Add to LazyGit config** (`~/.config/lazygit/config.yml`):
```yaml
customCommands:
  - key: "<c-a>"
    description: "AI-powered conventional commit"
    context: "global"
    loadingText: "Generating commit messages..."
    prompts:
      - type: "menu"
        key: "Type"
        title: "Type of change"
        options:
          - name: "feat"
            value: "feat"
          - name: "fix"
            value: "fix"
          - name: "chore"
            value: "chore"
          - name: "docs"
            value: "docs"
          - name: "style"
            value: "style"
          - name: "refactor"
            value: "refactor"
          - name: "perf"
            value: "perf"
          - name: "test"
            value: "test"
      - type: "menuFromCommand"
        title: "AI Generated Commit Messages"
        key: "CommitFile"
        command: "lgaicm suggest --type {{.Form.Type}}"
        filter: '^(?P<label>.*?) <===> (?P<file>.*)$'
        valueFormat: '{{.file}}'
        labelFormat: '{{.label}}'
    command: "lgaicm commit --file {{.Form.CommitFile | quote}}"
```

**That's it!** Stage your changes in LazyGit and press `Ctrl+A` to get AI-generated commit messages.

---

## Features

- 🤖 **AI-Powered**: Leverages OpenAI's API to analyze git diffs and generate meaningful commit messages
- 📝 **Conventional Commits**: Generates messages following the conventional commits specification
- 🎯 **Type Selection**: Choose specific commit types (feat, fix, chore, etc.) or let AI decide
- 🔧 **Highly Configurable**: Customize model, timeouts, message count, and diff limits via environment variables
- ⚡ **Fast Integration**: Seamlessly integrates with LazyGit's custom commands
- 🎨 **Multiple Suggestions**: Get 5-7 different commit message options to choose from
- 📄 **Multi-line Support**: Full support for commit messages with subject and detailed body

## Detailed Installation

### Alternative PATH Setup

Instead of a symbolic link, you can add the script directory to your PATH in your shell configuration file (`~/.bashrc`, `~/.zshrc`, etc.):

```bash
export PATH="$PATH:/path/to/lgaicm"
```

### Full LazyGit Configuration (with all commit types)

The Quick Start shows a simplified config. For all conventional commit types with descriptions, use this in your LazyGit config file (typically `~/.config/lazygit/config.yml` or `~/Library/Application Support/lazygit/config.yml` on macOS):

```yaml
customCommands:
  - key: "<c-a>"
    description: "AI-powered conventional commit (multiline)"
    context: "global"
    loadingText: "Generating commit messages..."
    prompts:
      - type: "menu"
        key: "Type"
        title: "Type of change"
        options:
          - name: "feat"
            description: "A new feature"
            value: "feat"
          - name: "fix"
            description: "A bug fix"
            value: "fix"
          - name: "chore"
            description: "Maintenance / tooling / non-user-facing"
            value: "chore"
          - name: "docs"
            description: "Documentation only"
            value: "docs"
          - name: "style"
            description: "Formatting / linting / no behavior change"
            value: "style"
          - name: "refactor"
            description: "Refactor without behavior change"
            value: "refactor"
          - name: "perf"
            description: "Performance improvement"
            value: "perf"
          - name: "test"
            description: "Add or update tests"
            value: "test"
          - name: "ci"
            description: "CI configuration / scripts"
            value: "ci"
          - name: "build"
            description: "Build system / dependencies"
            value: "build"

      - type: "menuFromCommand"
        title: "AI Generated Commit Messages"
        key: "CommitFile"
        command: "lgaicm suggest --type {{.Form.Type}}"
        filter: '^(?P<label>.*?) <===> (?P<file>.*)$'
        valueFormat: '{{.file}}'
        labelFormat: '{{.label}}'

    command: "lgaicm commit --file {{.Form.CommitFile | quote}}"
```

**Note**: If `lgaicm` is not in your PATH, update the `command` values to use the full path, e.g., `"/path/to/lgaicm suggest --type {{.Form.Type}}"`.

## Usage

### In LazyGit (Recommended)

1. Stage your changes in LazyGit
2. Press `Ctrl+A` (or your configured key)
3. Select the commit type from the menu
4. Review AI-generated commit message suggestions
5. Select your preferred message
6. The commit is created automatically

### Command Line

You can also use `lgaicm` directly from the command line:

```bash
# Generate suggestions
lgaicm suggest --type feat
lgaicm suggest --type fix
lgaicm suggest --type chore

# Create commit from selected message file
lgaicm commit --file /tmp/lgaicm.XXXXXX/msg-001.txt

# Show help
lgaicm --help
```

The `suggest` subcommand outputs lines in the format:
```
<subject> <===> <path-to-message-file>
```

The `commit` subcommand creates the commit using the selected message file and cleans up temporary files.

**Note**: You must have staged changes before running the command, or it will return an error.

## Configuration

`lgaicm` can be customized using environment variables. Add these to your shell configuration file for persistent settings:

### API Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENAI_API_KEY` | *(required)* | Your OpenAI API key |
| `LGAICM_MODEL` | `gpt-5.1-codex-max` | OpenAI model to use |
| `LGAICM_API_URL` | `https://api.openai.com/v1/responses` | OpenAI API endpoint |
| `LGAICM_CURL_TIMEOUT` | `45` | API request timeout in seconds |

### Output Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `LGAICM_MIN_SUGGESTIONS` | `5` | Minimum number of commit messages to generate |
| `LGAICM_MAX_SUGGESTIONS` | `7` | Maximum number of commit messages to generate |

### Diff Limits

| Variable | Default | Description |
|----------|---------|-------------|
| `LGAICM_MAX_STAT_BYTES` | `60000` | Maximum bytes from `git diff --stat` |
| `LGAICM_MAX_DIFF_BYTES` | `200000` | Maximum bytes from `git diff` |
| `LGAICM_MAX_SUBJECT_LENGTH` | `50` | Maximum length for commit subject line |

### Example Configuration

```bash
# ~/.bashrc or ~/.zshrc

# Required
export OPENAI_API_KEY="sk-proj-..."

# Optional customizations
export LGAICM_MODEL="gpt-4"
export LGAICM_MIN_SUGGESTIONS="3"
export LGAICM_MAX_SUGGESTIONS="5"
export LGAICM_CURL_TIMEOUT="60"
export LGAICM_MAX_DIFF_BYTES="150000"
export LGAICM_MAX_SUBJECT_LENGTH="50"
```

## Conventional Commit Types

The tool supports all standard conventional commit types:

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **perf**: A code change that improves performance
- **test**: Adding missing tests or correcting existing tests
- **build**: Changes that affect the build system or external dependencies
- **ci**: Changes to CI configuration files and scripts
- **chore**: Other changes that don't modify src or test files

## Troubleshooting

### "OPENAI_API_KEY environment variable is not set"

Make sure you've exported your OpenAI API key:

```bash
export OPENAI_API_KEY="your-api-key"
```

### "No staged changes detected"

You need to stage files before generating commit messages:

```bash
git add <files>
```

In LazyGit, select files and press `space` to stage them.

### "Required command 'jq' is not available"

Install `jq`:

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# Fedora
sudo dnf install jq

# Arch Linux
sudo pacman -S jq
```

### API timeout errors

Increase the timeout value:

```bash
export LGAICM_CURL_TIMEOUT="90"
```

### Empty or invalid responses

Try using a different model:

```bash
export LGAICM_MODEL="gpt-4"
```

## How It Works

### Suggest Phase

1. **Diff Collection**: The script runs `git diff --cached --stat` and `git diff --cached` to collect your staged changes
2. **Truncation**: Large diffs are truncated to stay within API limits (configurable byte limits)
3. **API Request**: The diff is sent to OpenAI's Responses API with instructions to generate conventional commit messages with subjects and bodies
4. **Response Processing**: The API response is parsed as JSON array of `{subject, body}` objects
5. **File Creation**: Each suggestion is written to a temporary file in `/tmp/lgaicm.XXXXXX/`
6. **Output**: Returns lines in format `<subject> <===> <file-path>` for LazyGit menu selection

### Commit Phase

1. **Commit Creation**: The selected message file (containing subject and body) is used with `git commit -F`
2. **Cleanup**: The temporary session directory is automatically removed after successful commit

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly
5. Commit your changes using conventional commits
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [LazyGit](https://github.com/jesseduffield/lazygit) - The amazing terminal UI for git
- [Conventional Commits](https://www.conventionalcommits.org/) - The commit message specification
- [OpenAI](https://openai.com/) - AI-powered analysis

## Related Projects

- [LazyGit](https://github.com/jesseduffield/lazygit)
- [commitizen](https://github.com/commitizen/cz-cli)
- [conventional-changelog](https://github.com/conventional-changelog/conventional-changelog)

---

Made with ❤️ for developers who love clean commit histories
