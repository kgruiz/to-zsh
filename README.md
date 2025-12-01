# to-zsh

> Prefer the Rust-based successor here: [goto](https://github.com/kgruiz/goto).

`to-zsh` provides persistent, keyword-based directory shortcuts with iterative prefix matching for Zsh, enabling instant navigation to saved or nested subdirectories without typing full paths. Assign memorable keywords to frequently accessed directories and traverse deeper paths seamlessly.

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
- **Iterative Prefix Matching:** Supports nested subdirectory navigation by matching the longest saved keyword prefix and appending the remainder.
- **Automatic Directory Creation:** Missing nested paths are created on the fly unless `--no-create` is used.
- **Automatic Editor Launch:** Use `-c`/`--cursor` to automatically run `cursor .` after changing directories.
- **Shell Autocomplete:** Tab-completion for commands and saved keywords.
- **Simple Shortcut Management:** Easily add (`--add`/`-a`), add in bulk (`--add-bulk`), copy (`--copy`), remove (`--rm`/`-r`), and list (`--list`/`-l`) your shortcuts.
- **Relative Path Support:** Accepts relative or absolute directory paths, resolving relative paths to their absolute form automatically.
- **Persistent Storage:** Shortcuts are stored in `~/.to_dirs`, ensuring they persist across shell sessions.
- **Lightweight Integration:** Implemented as a single Zsh script file.
- **Informative Output:** Utilizes clear, color-coded feedback.

## Installation

**Quick Install Script**

From the repository root run:

```zsh
zsh install.sh
```

The script copies `to.zsh` to `~/.config/zsh/plugins/to-zsh/` and inserts the recommended init block into `~/.zshrc` (updating it if already present). Reload your shell with `source ~/.zshrc` after running it.

1. **Clone the Repository (or Download `to.zsh`)**
    Choose a location for the script (e.g., `~/.config/zsh/plugins/to-zsh`).

    ```zsh
    # Option 1: Clone the repository
    git clone https://github.com/kgruiz/to-zsh.git ~/.config/zsh/plugins/to-zsh

    # Option 2: Create the directory and download the file
    mkdir -p ~/.config/zsh/plugins/to-zsh
    curl -o ~/.config/zsh/plugins/to-zsh/to.zsh https://raw.githubusercontent.com/kgruiz/to-zsh/main/to.zsh
    ```

2. **Source the Script in `.zshrc`**
    Add the following snippet to your `~/.zshrc` configuration file. Adjust `TO_FUNC_PATH` to the actual location where you placed `to.zsh`.

    ```zsh
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

    ```zsh
    source ~/.zshrc
    ```

## Usage Guide

The `to` command facilitates shortcut management and execution.

**1. Adding a Shortcut**
Register a new shortcut using `to --add <keyword> <path> [--expire <timestamp>]`, the shorthand `to -a <keyword> <path>`, or simply `to --add <path>` which uses the directory name as the keyword automatically. The optional `--expire` flag sets an expiration time in epoch seconds. The specified path can be relative or absolute; relative paths will be resolved to their absolute form automatically.

```zsh
❯ to --add proj ../my-project --expire 1700000000
Added proj → ../my-project (expires 1700000000)
❯ to --add ../another-project
Added another-project → ../another-project
```

**Bulk Adding Shortcuts**
Use `to --add-bulk <pattern>` to add shortcuts for each directory that matches the given glob pattern. The keyword defaults to the directory name.

```zsh
❯ to --add-bulk ../projects/*
Added alpha → /absolute/path/projects/alpha
Added beta → /absolute/path/projects/beta
```

**2. Jumping to a Saved Directory**
Navigate to a directory or nested subdirectory using `to <keyword>` or `to <keyword>/subdir`. The script selects the longest matching keyword prefix and appends any remaining path segments.

Examples:

```zsh
# Simple match using base keyword
❯ to proj/docs
Changed directory to ~/Development/my-project/docs

# Deeper nested path; longest prefix matching
❯ to proj/src/components/button
Changed directory to ~/Development/my-project/src/components/button

# When both proj and proj/src exist as shortcuts, prefix matching chooses proj/src
proj=/Development/my-project
proj/src=/Development/my-project/src

❯ to proj/src/utils
Changed directory to /Development/my-project/src/utils
```

**Running Cursor IDE**
Append `-c` or `--cursor` to open Cursor in the target directory:

```zsh
❯ to -c proj/docs
Changed directory to ~/Development/my-project/docs
# Cursor opens in that directory
```

**3. Listing Saved Shortcuts**
Display all currently registered shortcuts with `to --list` or `to -l`.

```zsh
❯ to --list
proj → ~/Development/my-project
docs → /usr/share/doc
conf → ~/.config
dotfiles → ~/Repositories/dotfiles
```

**4. Printing a Stored or Nested Path**
Print the stored base path or nested path using prefix matching: `to -p <keyword>` or `to -p <keyword>/subdir`.

```zsh
❯ to -p proj/src/utils
~/Development/my-project/src/utils

❯ to -p docs/api/v1
/usr/share/doc/api/v1
```

**5. Removing a Shortcut**
Delete an existing shortcut using `to --rm <keyword>` or `to -r <keyword>`.

```zsh
❯ to --rm docs
Removed docs.
```

**6. Displaying Help Information**
View the command usage and options with `to --help` or `to -h`.

```zsh
❯ to --help
to - Persistent Directory Shortcuts

Usage:
  to <keyword>                       Navigate to saved shortcut
  to --add, -a <keyword> <path>      Save new shortcut
  to --add <path>                    Save shortcut using directory name
  to --add-bulk <pattern>           Add shortcuts for each matching directory
  to --copy <existing> <new>        Duplicate a saved shortcut
  to --rm,  -r <keyword>             Remove existing shortcut
  to --list, -l                      List all shortcuts
  to --print-path, -p <keyword>      Print stored path only
  to --cursor, -c <keyword>            Open in Cursor after navigation
  to --no-create <keyword>           Jump without creating missing directories
  to --sort, -s <mode>               Set sorting mode (added | alpha | recent)
  to --add <k> <path> --expire <ts>  Save shortcut with expiration
  to --help, -h                      Show this help

Options:
  keyword                            Shortcut name
  --add, -a                          Add new shortcut
  --add-bulk                         Add shortcuts from pattern
  --copy                             Duplicate a shortcut
  --rm, -r                           Remove shortcut
  --list, -l                         List shortcuts
  --print-path, -p                   Print path only
  --expire                           Set expiration epoch time
  --cursor, -c                         Open in Cursor
  --no-create                        Disable automatic directory creation
  --sort, -s                         Set sorting mode
  --help, -h                         Show help
```

Running `to` without arguments displays this help along with a list of
saved shortcuts formatted in three columns:

```zsh
❯ to
to - Persistent Directory Shortcuts

Usage:
  to <keyword>                       Navigate to saved shortcut
  …
  --help, -h                         Show this help

Saved shortcuts:
  1. proj        4. src         7. utils
  2. docs        5. images      8. tmp
  3. conf        6. builds      9. dotfiles
```

## Options

| Option              | Short | Description                         |
|---------------------|-------|-------------------------------------|
| `--add [<k>] <path>`| `-a`  | Add a new shortcut; if `k` is omitted the directory name is used. |
| `--add-bulk <pattern>` |       | Add shortcuts for each directory matching `pattern`. |
| `--copy <existing> <new>` |       | Duplicate a saved shortcut. |
| `--rm <k>`          | `-r`  | Remove shortcut associated with `k`.|
| `--list`            | `-l`  | List all saved shortcuts.           |
| `--print-path <k>`  | `-p`  | Print stored or nested path using prefix matching.              |
| `--expire <ts>`     |       | Expire the shortcut after the given epoch timestamp. |
| `--cursor`            | `-c`  | Run `cursor .` in target directory after navigation. |
| `--no-create`       |       | Do not create nested directories on jump. |
| `--sort <mode>`     | `-s`  | Set sorting mode (`added`, `alpha`, or `recent`). |
| `--help`            | `-h`  | Show help message and usage.        |

## Configuration Details

- Directory shortcuts are stored line by line in the `~/.to_dirs` file.
- Each line follows the format: `keyword=absolute_path`.
- Expiration timestamps are stored separately in `~/.to_dirs_meta` as `keyword=epoch_timestamp` entries.
- While direct editing of `~/.to_dirs` is possible, using the `to --add` and `to --rm` commands ensures proper formatting and validation.
- User preferences can be defined in `~/.to_zsh_config`:
- `sort_order=added|alpha|recent` controls how shortcuts are listed and suggested.
    If omitted, the default is `added`, preserving the order in which shortcuts were saved.
    The `recent` option uses timestamps stored in `~/.to_dirs_recent` which are
    updated each time a shortcut is used.
  - Use `--sort <mode>` to change the sorting mode, which is written to `~/.to_zsh_config`.

## Contributing

Contributions, bug reports, and feature suggestions are welcome. Please refer to the repository's [issues tracker](https://github.com/kgruiz/to-zsh/issues) for ongoing development and discussion.

## License

Distributed under the **GNU GPL v3.0**.
See [LICENSE](LICENSE) or <https://www.gnu.org/licenses/gpl-3.0.html> for details.
