# `lgaicm` - LazyGit AI Commit Message

AI-powered conventional commit message generator for LazyGit.

`lgaicm` integrates with [LazyGit](https://github.com/jesseduffield/lazygit) to automatically generate conventional commit messages using OpenAI's API. It analyzes your staged changes and suggests multiple commit messages following the [Conventional Commits](https://www.conventionalcommits.org/) specification.

## Features

- 🤖 **AI-Powered**: Leverages OpenAI's API to analyze git diffs and generate meaningful commit messages
- 📝 **Conventional Commits**: Generates messages following the conventional commits specification
- 🎯 **Type Selection**: Choose specific commit types (feat, fix, chore, etc.) or let AI decide
- 🔧 **Highly Configurable**: Customize model, timeouts, message count, and diff limits via environment variables
- ⚡ **Fast Integration**: Seamlessly integrates with LazyGit's custom commands
- 🎨 **Multiple Suggestions**: Get 5-7 different commit message options to choose from

## Prerequisites

- `bash` (version 4.0 or higher recommended)
- `git`
- `curl`
- `jq`
- [LazyGit](https://github.com/jesseduffield/lazygit)
- OpenAI API key

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/lgaicm.git
cd lgaicm
```

### 2. Make the script executable

```bash
chmod +x lgaicm.sh
```

### 3. Add to your PATH

Create a symbolic link to a directory in your PATH:

```bash
ln -s "$(pwd)/lgaicm.sh" /usr/local/bin/lgaicm
```

Or add the script directory to your PATH in your shell configuration file (`~/.bashrc`, `~/.zshrc`, etc.):

```bash
export PATH="$PATH:/path/to/lgaicm"
```

### 4. Set your OpenAI API key

Add your OpenAI API key to your shell configuration:

```bash
export OPENAI_API_KEY="your-openai-api-key-here"
```

For persistent configuration, add this to your `~/.bashrc`, `~/.zshrc`, or `~/.profile`.

## LazyGit Configuration

Add the following custom command to your LazyGit configuration file (typically located at `~/.config/lazygit/config.yml` or `~/Library/Application Support/lazygit/config.yml` on macOS):

```yaml
customCommands:
  - key: <c-a>
    description: AI-powered conventional commit
    context: global
    prompts:
      - type: "menu"
        key: "Type"
        title: "Type of change"
        options:
          - name: "AI defined"
            description: "Let AI analyze and determine the best commit type"
            value: "ai-defined"
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
          - name: "refactor"
            description: "A code change that neither fixes a bug nor adds a feature"
            value: "refactor"
          - name: "test"
            description: "Adding missing tests or correcting existing tests"
            value: "test"
      - type: menuFromCommand
        title: "AI Generated Commit Messages"
        key: CommitMsg
        command: "lgaicm --type {{.Form.Type}}"
    command: "git commit -m \"{{.Form.CommitMsg}}\""
    loadingText: "Generating commit messages..."
```

## Usage

### Within LazyGit

1. Stage your changes in LazyGit
2. Press `Ctrl+A` (or your configured key)
3. Select the commit type from the menu (or choose "AI defined")
4. Review the AI-generated commit message suggestions
5. Select your preferred message
6. The commit will be created automatically

### Command Line

You can also use `lgaicm` directly from the command line:

```bash
# Let AI determine the commit type
lgaicm

# Specify a commit type
lgaicm --type feat
lgaicm --type fix
lgaicm --type chore

# Show help
lgaicm --help
```

**Note**: You must have staged changes before running the command, or it will return an error.

## Configuration

`lgaicm` can be customized using environment variables. Add these to your shell configuration file for persistent settings:

### API Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENAI_API_KEY` | *(required)* | Your OpenAI API key |
| `LGAICM_MODEL` | `gpt-5.1-codex-mini` | OpenAI model to use |
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
| `LGAICM_MAX_STAT_CHARS` | `60000` | Maximum characters from `git diff --stat` |
| `LGAICM_MAX_DIFF_CHARS` | `200000` | Maximum characters from `git diff` |

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
export LGAICM_MAX_DIFF_CHARS="150000"
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

1. **Diff Collection**: The script runs `git diff --cached --stat` and `git diff --cached` to collect your staged changes
2. **Truncation**: Large diffs are truncated to stay within API limits
3. **API Request**: The diff is sent to OpenAI's Responses API with instructions to generate conventional commit messages
4. **Response Processing**: The API response is parsed, cleaned, and formatted
5. **Output**: Multiple commit message suggestions are returned for selection

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
