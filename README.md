# `lgaicm` - LazyGit AI Commit Message

**Generate AI-powered conventional commit messages directly in LazyGit.** Press a hotkey, select a commit type, choose from AI-generated suggestions, and commit—all without leaving LazyGit.

## Quick Start

### What You Need
- [LazyGit](https://github.com/jesseduffield/lazygit) installed
- Google AI API key (for Gemini)
- `bash`, `git`, `curl`, `jq`, and `mktemp` (standard in `coreutils`)

### Setup in 3 Steps

**1. Install `lgaicm`:**
```bash
git clone https://github.com/rakotomandimby/lgaicm.git
cd lgaicm
chmod +x lgaicm
ln -s "$(pwd)/lgaicm" /usr/local/bin/lgaicm
```

**2. Set your Google AI API key:**
```bash
export GOOGLEAI_API_KEY="your-google-ai-api-key-here"
# Add to ~/.bashrc or ~/.zshrc for persistence
```

**3. Add to LazyGit config** (`~/.config/lazygit/config.yml`):

Copy the content of [./lazygit-config.yml](./lazygit-config.yml) and append it to your LazyGit configuration file.

**That's it!** Stage your changes in LazyGit and press `Ctrl+A` to generate and select AI-powered commit messages.

---

## Features

- 🤖 **AI-Powered**: Leverages Google Gemini models to analyze git diff stats and patches to generate meaningful commit messages.
- 📝 **Conventional Commits**: Enforces conventional commit formatting with mandatory type prefixing and scope inference.
- 🎯 **Type Selection**: Choose from allowed conventional commit types (`feat`, `fix`, `chore`, `docs`, `style`, `refactor`, `perf`, `test`, `ci`, `build`).
- 🔧 **Highly Configurable**: Customize model, endpoint URL, timeouts, suggestion counts, diff truncation limits, subject length, and debug logs via environment variables.
- ⚡ **Fast Integration**: Seamlessly integrates with LazyGit's `customCommands` and `menuFromCommand`.
- 🎨 **Multiple Suggestions**: Generates a configurable number of distinct commit message options (default 5–7).
- 📄 **Multi-line Safe**: Produces comprehensive commit messages with subject lines and detailed multi-line bodies covering changes, risks, and regression testing tips.

---

## Usage

### In LazyGit (Recommended)

1. Stage your changes in LazyGit (`space` on modified files).
2. Press `Ctrl+A` (or your configured keybinding).
3. Select the commit type from the prompt menu.
4. Review the AI-generated commit message suggestions in the submenu.
5. Select your preferred message to commit automatically.

### Command Line

You can also run `lgaicm` directly from your terminal:

```bash
# Generate suggestions (requires staged changes)
lgaicm suggest --type feat
lgaicm suggest -t fix

# Commit using a selected suggestion file
lgaicm commit --file /tmp/lgaicm.XXXXXX/msg-001.txt
lgaicm commit -f /tmp/lgaicm.XXXXXX/msg-001.txt

# Show usage and available options
lgaicm --help
```

The `suggest` subcommand outputs lines in the delimiter format expected by LazyGit:
```text
<subject> <===> <path-to-message-file>
```

The `commit` subcommand creates the commit using `git commit -F <path>` and cleans up the temporary session directory.

---

## Configuration

`lgaicm` is configured via environment variables. You can set them in your shell configuration file (`~/.bashrc`, `~/.zshrc`, etc.):

### API Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `GOOGLEAI_API_KEY` | *(required)* | Your Google AI API key |
| `LGAICM_MODEL` | `gemini-3.5-flash-lite` | Gemini model name |
| `LGAICM_API_URL` | `https://aiplatform.googleapis.com/v1/publishers/google/models` | Base Vertex AI endpoint or generateContent endpoint URL (see URL resolution rules below) |
| `LGAICM_CURL_TIMEOUT` | `45` | API request timeout in seconds |

#### Endpoint URL Resolution Rules

`lgaicm` resolves `LGAICM_API_URL` using the following rules:

1. **Default / Base URL**: Treated as the base Vertex AI endpoint (`https://aiplatform.googleapis.com/v1/publishers/google/models`). `lgaicm` automatically appends `/<LGAICM_MODEL>:generateContent`.
2. **Template Substitution**: Any `{model}` or `{MODEL}` placeholder in `LGAICM_API_URL` is substituted with the value of `LGAICM_MODEL`.
3. **Explicit Endpoint**: If `LGAICM_API_URL` already contains `:generateContent`, it is used directly as-is without appending model paths.

### Output & Diff Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `LGAICM_MIN_SUGGESTIONS` | `5` | Minimum number of commit message suggestions to request |
| `LGAICM_MAX_SUGGESTIONS` | `7` | Maximum number of commit message suggestions to request |
| `LGAICM_MAX_SUBJECT_LENGTH` | `500` | Maximum character length for normalized commit subject lines |
| `LGAICM_MAX_STAT_BYTES` | `60000` | Maximum byte limit for `git diff --cached --stat` before truncation |
| `LGAICM_MAX_DIFF_BYTES` | `200000` | Maximum byte limit for `git diff --cached` patch before truncation |
| `LGAICM_DEBUG_LOG` | `/tmp/lgaicm_debug.log` | Target file path for detailed debug logging |

### Example Configuration

```bash
# ~/.bashrc or ~/.zshrc

# Required
export GOOGLEAI_API_KEY="your-google-ai-api-key"

# Optional customizations
export LGAICM_MODEL="gemini-3.5-flash-lite"
export LGAICM_API_URL="https://aiplatform.googleapis.com/v1/publishers/google/models"
export LGAICM_MIN_SUGGESTIONS="3"
export LGAICM_MAX_SUGGESTIONS="5"
export LGAICM_CURL_TIMEOUT="60"
export LGAICM_MAX_STAT_BYTES="60000"
export LGAICM_MAX_DIFF_BYTES="200000"
export LGAICM_MAX_SUBJECT_LENGTH="100"
export LGAICM_DEBUG_LOG="/tmp/lgaicm_debug.log"
```

---

## Conventional Commit Types

The script strictly validates and accepts the following commit types:

| Type | Description |
|------|-------------|
| `feat` | A new feature |
| `fix` | A bug fix |
| `chore` | Maintenance, tooling, or non-user-facing changes |
| `docs` | Documentation only changes |
| `style` | Formatting, missing semi-colons, whitespace, etc. (no code behavior change) |
| `refactor` | Code restructuring without fixing a bug or adding a feature |
| `perf` | Performance improvement changes |
| `test` | Adding or updating tests |
| `ci` | CI/CD configuration files and scripts |
| `build` | Build system or external dependencies changes |

---

## How It Works

### Suggest Phase (`lgaicm suggest --type <type>`)

1. **Prerequisite Verification**: Checks for `git`, `curl`, `jq`, `mktemp`, a valid git repository, staged changes, and `GOOGLEAI_API_KEY`.
2. **Diff Collection & Safety Truncation**: Extracts `git diff --cached --stat` and `git diff --cached`, truncating them safely according to `LGAICM_MAX_STAT_BYTES` and `LGAICM_MAX_DIFF_BYTES`.
3. **Structured Prompt Generation**: Builds a prompt enforcing JSON output (`[{ "subject": "...", "body": "..." }]`), conventional commit rules, subject line wrapping, and multi-paragraph commit bodies covering what changed, why, behavior changes, risks, and regression testing steps.
4. **API Request**: Calls the Gemini `generateContent` endpoint using `curl` with `responseMimeType: "application/json"`.
5. **JSON Extraction & Subject Normalization**: Extracts candidate text, parses the JSON array, ensures the type prefix is present, strips trailing periods, and trims whitespace.
6. **Temporary File Storage**: Writes each message to an isolated temporary session folder (`/tmp/lgaicm.XXXXXX/msg-XXX.txt`) and emits `<subject> <===> <path>` lines for LazyGit.

### Commit Phase (`lgaicm commit --file <path>`)

1. **Commit Execution**: Reads the full multi-line commit message from the file using `git commit -F <file>`.
2. **Session Cleanup**: Identifies the parent session directory via the `.lgaicm_session` marker and removes the temporary directory upon completion.

---

## Troubleshooting & Debugging

### Debug Logs

`lgaicm` writes comprehensive debug information—including API request payloads, raw API responses, candidate finish reasons, and session paths—to `LGAICM_DEBUG_LOG` (defaults to `/tmp/lgaicm_debug.log`).

You can inspect the log in real time with:
```bash
tail -f /tmp/lgaicm_debug.log
```

### Common Errors

- **`Error: GOOGLEAI_API_KEY environment variable is not set.`**  
  Export your API key before launching LazyGit or running `lgaicm`:
  ```bash
  export GOOGLEAI_API_KEY="your-api-key"
  ```

- **`Error: No staged changes detected. Stage files before generating commit messages.`**  
  Stage the intended changes with `git add <files>` (or press `space` in LazyGit) before executing the suggest command.

- **`Error: Not inside a git repository.`**  
  Ensure you are executing the command within a valid Git working tree.

- **`Error: Required command 'jq' is not available in PATH.`**  
  Install missing dependencies (`git`, `curl`, `jq`):
  ```bash
  # macOS
  brew install jq

  # Debian / Ubuntu
  sudo apt-get install jq

  # Fedora
  sudo dnf install jq

  # Arch Linux
  sudo pacman -S jq
  ```

- **API timeout errors / `Failed to call Gemini generateContent API (network/timeout)`**  
  Increase the curl timeout:
  ```bash
  export LGAICM_CURL_TIMEOUT="90"
  ```

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly
5. Commit your changes using conventional commits
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

