# to-zsh

`to-zsh` provides persistent, keyword-based directory shortcuts for Zsh, streamlining your command-line navigation. It eliminates the need to repeatedly type lengthy directory paths by allowing you to assign memorable keywords to frequently accessed directories and jump to them instantly.

## Table of Contents

- [Key Features](#key-features)
- [Installation](#installation)
- [Usage Guide](#usage-guide)
- [Options](#options)
- [Configuration Details](#configuration-details)
- [Contributing](#contributing)
- [License](#license)

## Key Features

- **Keyword-Based Navigation:** Assign concise keywords to directory paths.
- **Instant Directory Switching:** Navigate quickly using the `to <keyword>` command.
- **Shell Autocomplete:** Tab-completion for commands and saved keywords.
- **Simple Shortcut Management:** Easily add (`--add`/`-a`), remove (`--rm`/`-r`), and list (`--list`/`-l`) your shortcuts.
- **Relative Path Support:** Accepts relative or absolute directory paths, resolving relative paths to their absolute form automatically.
- **Persistent Storage:** Shortcuts are stored in `~/.to_dirs`, ensuring they persist across shell sessions.
- **Lightweight Integration:** Implemented as a single Zsh script file.
- **Informative Output:** Utilizes clear, color-coded feedback.

## Installation

1. **Clone the Repository (or Download `to.zsh`)**
    Choose a location for the script (e.g., `~/.config/zsh/plugins/to-zsh`).

    ```bash
    # Option 1: Clone the repository
    git clone https://github.com/kgruiz/to-zsh.git ~/.config/zsh/plugins/to-zsh

    # Option 2: Create the directory and download the file
    mkdir -p ~/.config/zsh/plugins/to-zsh
    curl -o ~/.config/zsh/plugins/to-zsh/to.zsh https://raw.githubusercontent.com/kgruiz/to-zsh/main/to.zsh
    ```

2. **Source the Script in `.zshrc`**
    Add the following snippet to your `~/.zshrc` configuration file. Adjust `TO_FUNC_PATH` to the actual location where you placed `to.zsh`.

    ```bash
    # init zsh completion
    autoload -Uz compinit
    compinit

    # load to-zsh
    TO_FUNC_PATH="$HOME/.config/zsh/plugins/to-zsh/to.zsh"
    if [ -f "$TO_FUNC_PATH" ]; then
      if ! . "$TO_FUNC_PATH" 2>&1; then
        echo "Error: Failed to source \"$(basename "$TO_FUNC_PATH")\"" >&2
      fi
    else
      echo "Error: \"$(basename "$TO_FUNC_PATH")\" not found at:" >&2
      echo "  $TO_FUNC_PATH" >&2
    fi
    unset TO_FUNC_PATH
    ```

3. **Apply Changes**

    ```bash
    source ~/.zshrc
    ```

## Usage Guide

The `to` command facilitates shortcut management and execution.

**1. Adding a Shortcut**
Register a new shortcut using `to --add <keyword> <path>` or the shorthand `to -a <keyword> <path>`. The specified path can be relative or absolute; relative paths will be resolved to their absolute form automatically.

```bash
❯ to --add proj ../my-project
Added proj → ../my-project
```

**2. Jumping to a Saved Directory**
Navigate to a directory associated with a keyword using `to <keyword>`.

```bash
❯ to proj
Changed directory to ~/Development/my-project

❯ pwd
/Users/youruser/Development/my-project
```

**3. Listing Saved Shortcuts**
Display all currently registered shortcuts with `to --list` or `to -l`.

```bash
❯ to --list
proj → ~/Development/my-project
docs → /usr/share/doc
conf → ~/.config
dotfiles → ~/Repositories/dotfiles
```

**4. Removing a Shortcut**
Delete an existing shortcut using `to --rm <keyword>` or `to -r <keyword>`.

```bash
❯ to --rm docs
Removed docs.
```

**5. Displaying Help Information**
View the command usage and options with `to --help` or `to -h`.

```bash
❯ to --help
to - Persistent Directory Shortcuts

Usage:
  to <keyword>                       Navigate to saved shortcut
  to --add, -a <keyword> <path>      Save new shortcut
  to --rm,  -r <keyword>             Remove existing shortcut
  to --list, -l                      List all shortcuts
  to --print-path, -p <keyword>      Print stored path only
  to --help, -h                      Show this help

Options:
  keyword                            Shortcut name
  --add, -a                          Add new shortcut
  --rm, -r                           Remove shortcut
  --list, -l                         List shortcuts
  --print-path, -p                   Print path only
  --help, -h                         Show help
```

## Options

| Option              | Short | Description                         |
|---------------------|-------|-------------------------------------|
| `--add <k> <path>`  | `-a`  | Add a new shortcut `k` → `path`.    |
| `--rm <k>`          | `-r`  | Remove shortcut associated with `k`.|
| `--list`            | `-l`  | List all saved shortcuts.           |
| `--print-path <k>`  | `-p`  | Print stored path for `k` only.     |
| `--help`            | `-h`  | Show help message and usage.        |

## Configuration Details

- Directory shortcuts are stored line by line in the `~/.to_dirs` file.
- Each line follows the format: `keyword=absolute_path`.
- While direct editing of `~/.to_dirs` is possible, using the `to --add` and `to --rm` commands ensures proper formatting and validation.

## Contributing

Contributions, bug reports, and feature suggestions are welcome. Please refer to the repository's [issues tracker](https://github.com/kgruiz/to-zsh/issues) for ongoing development and discussion.

## License

Distributed under the **GNU GPL v3.0**.
See [LICENSE](LICENSE) or <https://www.gnu.org/licenses/gpl-3.0.html> for details.
