# Persistent Directory Shortcuts – `to` command

readonly ESC="\033"
readonly RESET="${ESC}[0m"
readonly BOLD_CYAN="${ESC}[1;36m"
readonly DIM_WHITE="${ESC}[2;37m"
readonly DIM_BLUE="${ESC}[2;34m"
readonly GREEN="${ESC}[0;32m"
readonly BOLD_RED="${ESC}[1;31m"
readonly YELLOW="${ESC}[0;33m"
readonly MAGENTA="${ESC}[0;35m"

readonly CONFIG_FILE="${HOME}/.to_dirs"

# Show usage/help
function ShowHelp {
    printf "${YELLOW}to - Persistent Directory Shortcuts${RESET}\n\n"

    printf "${MAGENTA}Usage:${RESET}\n"
    printf "  ${DIM_WHITE}to <keyword>${RESET}\n"
    printf "  ${DIM_WHITE}to --add <keyword> <path>${RESET}\n"
    printf "  ${DIM_WHITE}to --rm <keyword>${RESET}\n"
    printf "  ${DIM_WHITE}to --list${RESET}\n"
    printf "  ${DIM_WHITE}to --help${RESET}\n\n"

    printf "${MAGENTA}Commands:${RESET}\n"
    printf "  ${BOLD_CYAN}keyword${RESET}      Jump to saved directory\n"
    printf "  ${BOLD_CYAN}--add, -a${RESET}  Save new shortcut\n"
    printf "  ${BOLD_CYAN}--rm, -r${RESET}   Remove shortcut\n"
    printf "  ${BOLD_CYAN}--list, -l${RESET} List shortcuts\n"
    printf "  ${BOLD_CYAN}--help, -h${RESET} Show this help\n"
}

# List all saved shortcuts
function ListShortcuts {
    if [ ! -s "${CONFIG_FILE}" ]; then
        printf "${BOLD_RED}No shortcuts saved.${RESET}\n"
        return
    fi

    while IFS='=' read -r keyword targetPath; do
        printf "${BOLD_CYAN}%s${RESET} → ${DIM_WHITE}%s${RESET}\n" "$keyword" "$targetPath"
    done < "${CONFIG_FILE}"
}

# Add a new shortcut
function AddShortcut {
    local keyword="$1"
    local targetPath="$2"

    if [ -z "${keyword}" ] || [ -z "${targetPath}" ]; then
        printf "${BOLD_RED}Usage: to --add <keyword> <absolute_path>${RESET}\n"
        return
    fi

    if [[ "${targetPath}" != /* ]] || [ ! -d "${targetPath}" ]; then
        printf "${BOLD_RED}Error: Path must be absolute and exist.${RESET}\n"
        return
    fi

    if grep -q "^${keyword}=" "${CONFIG_FILE}" 2>/dev/null; then
        printf "${BOLD_RED}Error: Keyword '%s' already exists.${RESET}\n" "${keyword}"
        return
    fi

    echo "${keyword}=${targetPath}" >> "${CONFIG_FILE}"
    printf "${GREEN}Added ${BOLD_CYAN}%s${RESET}${GREEN} → ${DIM_WHITE}%s${RESET}\n" "${keyword}" "${targetPath}"
}

# Remove an existing shortcut
function RemoveShortcut {
    local keyword="$1"

    if [ -z "${keyword}" ]; then
        printf "${BOLD_RED}Usage: to --rm <keyword>${RESET}\n"
        return
    fi

    if ! grep -q "^${keyword}=" "${CONFIG_FILE}" 2>/dev/null; then
        printf "${BOLD_RED}Error: Keyword '%s' not found.${RESET}\n" "${keyword}"
        return
    fi

    grep -v "^${keyword}=" "${CONFIG_FILE}" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "${CONFIG_FILE}"
    printf "${GREEN}Removed ${BOLD_CYAN}%s${RESET}${GREEN}.${RESET}\n" "${keyword}"
}

# Jump to a saved directory
function JumpToShortcut {
    local keyword="$1"

    if [ -z "${keyword}" ]; then
        ShowHelp
        return
    fi

    local targetPath
    targetPath=$(grep "^${keyword}=" "${CONFIG_FILE}" | cut -d'=' -f2-)

    if [ -z "${targetPath}" ]; then
        printf "${BOLD_RED}Error: '%s' not found.${RESET}\n" "${keyword}"
        return
    fi

    cd "${targetPath}" || {
        printf "${BOLD_RED}Error: Failed to cd to '%s'.${RESET}\n" "${targetPath}"
        return
    }

    printf "${GREEN}Changed directory to ${DIM_WHITE}%s${RESET}\n" "${targetPath}"
}

# Main entrypoint
function to {
    if [ ! -f "${CONFIG_FILE}" ]; then
        touch "${CONFIG_FILE}"
    fi

    case "$1" in

        --help|-h)
            ShowHelp
            ;;

        --list|-l)
            ListShortcuts
            ;;

        --add|-a)
            AddShortcut "$2" "$3"
            ;;

        --rm|-r)
            RemoveShortcut "$2"
            ;;

        *)
            JumpToShortcut "$1"
            ;;

    esac
}