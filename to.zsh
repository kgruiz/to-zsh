# Persistent Directory Shortcuts – `to` command

# color codes (only define if not already set)
if [[ -z $ESC ]]; then readonly ESC="\033"; fi
if [[ -z $RESET ]]; then readonly RESET="${ESC}[0m"; fi
if [[ -z $BOLD_CYAN ]]; then readonly BOLD_CYAN="${ESC}[1;36m"; fi
if [[ -z $DIM_WHITE ]]; then readonly DIM_WHITE="${ESC}[2;37m"; fi
if [[ -z $DIM_BLUE ]]; then readonly DIM_BLUE="${ESC}[2;34m"; fi
if [[ -z $GREEN ]]; then readonly GREEN="${ESC}[0;32m"; fi
if [[ -z $BOLD_RED ]]; then readonly BOLD_RED="${ESC}[1;31m"; fi
if [[ -z $YELLOW ]]; then readonly YELLOW="${ESC}[0;33m"; fi
if [[ -z $MAGENTA ]]; then readonly MAGENTA="${ESC}[0;35m"; fi

CONFIG_FILE="${HOME}/.to_dirs"

# Show usage/help
function To_ShowHelp {
    printf "${YELLOW}to - Persistent Directory Shortcuts${RESET}\n\n"

    printf "${MAGENTA}Usage:${RESET}\n"
    printf "  ${DIM_WHITE}to <keyword>                       ${RESET}Navigate to saved shortcut\n"
    printf "  ${DIM_WHITE}to --add, -a <keyword> <path>     ${RESET} Save new shortcut\n"
    printf "  ${DIM_WHITE}to --rm,  -r <keyword>            ${RESET} Remove existing shortcut\n"
    printf "  ${DIM_WHITE}to --list, -l                     ${RESET} List all shortcuts\n"
    printf "  ${DIM_WHITE}to --print-path, -p <keyword>     ${RESET} Print stored path only\n"
    printf "  ${DIM_WHITE}to --help, -h                     ${RESET} Show this help\n\n"

    printf "${MAGENTA}Options:${RESET}\n"
    printf "  ${BOLD_CYAN}keyword                        ${RESET}    Shortcut name\n"
    printf "  ${BOLD_CYAN}--add, -a                      ${RESET}    Add new shortcut\n"
    printf "  ${BOLD_CYAN}--rm, -r                       ${RESET}    Remove shortcut\n"
    printf "  ${BOLD_CYAN}--list, -l                     ${RESET}    List shortcuts\n"
    printf "  ${BOLD_CYAN}--print-path, -p               ${RESET}    Print path only\n"
    printf "  ${BOLD_CYAN}--help, -h                     ${RESET}    Show help\n"
}

# List all saved shortcuts
function ListShortcuts {
    if [ ! -s "${CONFIG_FILE}" ]; then
        printf "${BOLD_RED}No shortcuts saved.${RESET}\n"
        return
    fi

    while IFS='=' read -r keyword targetPath || [ -n "$keyword" ]; do
        printf "${BOLD_CYAN}%s${RESET} → ${DIM_WHITE}%s${RESET}\n" "$keyword" "$targetPath"
    done <"${CONFIG_FILE}"
}

# Add a new shortcut
function AddShortcut {
    local keyword="$1"
    local targetPath="$2"

    if [ -z "${keyword}" ] || [ -z "${targetPath}" ]; then
        printf "${BOLD_RED}Usage: to --add <keyword> <path>${RESET}\n"
        return
    fi

    if [ ! -d "${targetPath}" ]; then
        return
    fi

    local absPath
    absPath=$(cd "${targetPath}" && pwd)

    if grep -q "^${keyword}=" "${CONFIG_FILE}" 2>/dev/null; then
        printf "${BOLD_RED}Error: Keyword '%s' already exists.${RESET}\n" "${keyword}"
        return
    fi

    printf '%s\n' "${keyword}=${absPath}" >>"${CONFIG_FILE}"
    printf "${GREEN}Added ${BOLD_CYAN}%s${RESET}${GREEN} → ${DIM_WHITE}%s${RESET}\n" "${keyword}" "${absPath}"
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

    grep -v "^${keyword}=" "${CONFIG_FILE}" >"${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "${CONFIG_FILE}"
    printf "${GREEN}Removed ${BOLD_CYAN}%s${RESET}${GREEN}.${RESET}\n" "${keyword}"
}

# Jump to a saved directory
function JumpToShortcut {
    local keyword="$1"

    if [ -z "${keyword}" ]; then
        To_ShowHelp
        # show up to 10 saved keywords
        if [ -r "${CONFIG_FILE}" ]; then
            local total shown i
            total=$(grep -c '^' "${CONFIG_FILE}")
            if [ "${total}" -le 10 ]; then
                printf "\n${MAGENTA}Saved shortcuts:${RESET}\n"
                i=1
                while IFS='=' read -r key _ || [ -n "$key" ]; do
                    printf "  ${YELLOW}%2d${RESET}. ${BOLD_CYAN}%s${RESET}\n" \
                        "${i}" "${key}"
                    ((i++))
                done <"${CONFIG_FILE}"
            else
                shown=10
                printf "\n${MAGENTA}Saved shortcuts (showing %d of %d):${RESET}\n" \
                    "${shown}" "${total}"
                i=1
                while IFS='=' read -r key _ && [ "${i}" -le "${shown}" ]; do
                    printf "  ${YELLOW}%2d${RESET}. ${BOLD_CYAN}%s${RESET}\n" \
                        "${i}" "${key}"
                    ((i++))
                done <"${CONFIG_FILE}"
                printf "  … and %d more\n" "$((total - shown))"
            fi
        fi

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

    # --print-path: print the stored path for a keyword and exit
    if [[ "$1" == "-p" || "$1" == "--print-path" ]]; then

        local keyword="$2"

        if [ -z "${keyword}" ]; then
            printf "${BOLD_RED}Usage: to -p <keyword>${RESET}\n"
            return 1
        fi

        # Extract path for keyword
        local match
        match=$(grep -m1 "^${keyword}=" "${CONFIG_FILE}" 2>/dev/null)

        if [ -z "${match}" ]; then
            printf "${BOLD_RED}Error: Shortcut '%s' not found.${RESET}\n" "${keyword}"
            return 1
        fi

        printf "%s\n" "${match#*=}"
        return
    fi

    case "$1" in

    --help | -h)
        To_ShowHelp
        ;;

    --list | -l)
        ListShortcuts
        ;;

    --add | -a)
        AddShortcut "$2" "$3"
        ;;

    --rm | -r)
        RemoveShortcut "$2"
        ;;

    *)
        JumpToShortcut "$1"
        ;;

    esac
}

# Zsh completion for `to`
if [[ -n $ZSH_VERSION ]]; then

    _to() {

        local state
        typeset -A opt_args
        _arguments \
            '1:command:->cmds' \
            '*:keyword:->keywords'

        case $state in
        cmds)
            compadd -- --help -h --list -l --add -a --rm -r
            ;;
        keywords)
            local -a keywords
            while IFS='=' read -r key _; do
                keywords+=("$key")
            done <"$CONFIG_FILE"
            compadd -- $keywords
            ;;
        esac
    }
    compdef _to to
fi
