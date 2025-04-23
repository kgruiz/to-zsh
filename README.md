# to-zsh

**`to-zsh` provides persistent, keyword-based directory shortcuts for Zsh, streamlining your command-line navigation.**

Eliminate the need to repeatedly type lengthy directory paths. With `to-zsh`, assign memorable keywords to frequently accessed directories and jump to them instantly.

✨ **Key Features**

- **Keyword-Based Navigation:** Assign concise keywords to directory paths.
- **Instant Directory Switching:** Navigate quickly using the `to <keyword>` command.
- **Simple Shortcut Management:** Easily add (`--add`), remove (`--rm`), and list (`--list`) your shortcuts.
- **Persistent Storage:** Shortcuts are stored in `~/.to_dirs`, ensuring they persist across shell sessions.
- **Lightweight Integration:** Implemented as a single Zsh script file.
- **Informative Output:** Utilizes clear, color-coded feedback.

💾 **Installation**

1.  **Clone the Repository (or Download `to.zsh`)**
    Choose a location for the script (e.g., `~/.config/zsh/plugins/to-zsh`).

    ```bash
    # Option 1: Clone the repository
    git clone <repository_url> ~/.config/zsh/plugins/to-zsh

    # Option 2: Create the directory and download the file
    # mkdir -p ~/.config/zsh/plugins/to-zsh
    # curl -o ~/.config/zsh/plugins/to-zsh/to.zsh <raw_url_to_to.zsh>
    ```

    _(Replace `<repository_url>` and `<raw_url_to_to.zsh>` with the actual URLs)_

2.  **Source the Script in `.zshrc`**
    Add the following snippet to your `~/.zshrc` configuration file. Adjust `TO_FUNC_PATH` to the actual location where you placed `to.zsh`.

    ```bash
    # Set the path to your to.zsh script
    TO_FUNC_PATH="$HOME/.config/zsh/plugins/to-zsh/to.zsh"

    if [ -f "$TO_FUNC_PATH" ]; then
        if ! source "$TO_FUNC_PATH" 2>/dev/null; then

            echo "Error: Failed to source 'to.zsh'. Verify the file's path and integrity." >&2
        fi
    else
        echo "Error: 'to.zsh' not found at $TO_FUNC_PATH. Please ensure the file exists." >&2
    fi
    ```

3.  **Apply Changes**
    Either restart your Zsh shell or source your updated configuration:
    ```bash
    source ~/.zshrc
    ```

💡 **Usage Guide**

The `to` command facilitates shortcut management and execution.

**1. Adding a Shortcut**

Register a new shortcut using `to --add <keyword> <absolute_path>` or the shorthand `to -a <keyword> <absolute_path>`. The specified path must be absolute and correspond to an existing directory.

```bash
❯ to --add proj ~/Development/my-project
Added proj → ~/Development/my-project
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
  to <keyword>
  to --add <keyword> <path>
  to --rm <keyword>
  to --list
  to --help

Commands:
  keyword      Jump to saved directory
  --add, -a  Save new shortcut
  --rm, -r   Remove shortcut
  --list, -l List shortcuts
  --help, -h Show this help
```

⚙️ **Configuration Details**

- Directory shortcuts are stored line by line in the `~/.to_dirs` file.
- Each line follows the format: `keyword=absolute_path`.
- While direct editing of `~/.to_dirs` is possible, using the `to --add` and `to --rm` commands ensures proper formatting and validation.

🤝 **Contributing**

Contributions, bug reports, and feature suggestions are welcome. Please refer to the repository's [issues tracker](https://github.com/kgruiz/to-zsh/issues) for ongoing development and discussion.

📜 **License**

This project is distributed under the terms of the **GNU General Public License v3.0**.

Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
Everyone is permitted to copy and distribute verbatim copies of this license document, but changing it is not allowed.

For the full license text, please refer to the [LICENSE](LICENSE) file included in the repository or visit <https://www.gnu.org/licenses/gpl-3.0.html>.
