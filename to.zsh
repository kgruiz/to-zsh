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

# Remove expired entries from CONFIG_FILE
function CleanExpiredShortcuts {
    [ ! -f "${CONFIG_FILE}" ] && return
    local now tmp changed=0
    now=$(date +%s)
    tmp="${CONFIG_FILE}.tmp"
    >"${tmp}"
    while IFS='=' read -r key value || [ -n "$key" ]; do
        [ -z "$key" ] && continue
        local path expire
        path="${value%%|*}"
        if [[ "$value" == *"|"* ]]; then
            expire="${value#*|}"
            if [[ -n "$expire" && "$expire" -le "$now" ]]; then
                changed=1
                continue
            fi
        fi
        if [ -n "$expire" ]; then
            printf '%s=%s|%s\n' "$key" "$path" "$expire" >>"${tmp}"
        else
            printf '%s=%s\n' "$key" "$path" >>"${tmp}"
        fi
    done <"${CONFIG_FILE}"
    if [ "$changed" -eq 1 ]; then
        mv "${tmp}" "${CONFIG_FILE}"
    else
        rm -f "${tmp}"
    fi
}

# Show usage/help
function To_ShowHelp {
    printf "${YELLOW}to - Persistent Directory Shortcuts${RESET}\n\n"

    printf "${MAGENTA}Usage:${RESET}\n"
    printf "  ${DIM_WHITE}to <keyword>                       ${RESET}Navigate to saved shortcut\n"
    printf "  ${DIM_WHITE}to --add, -a <keyword> <path>     ${RESET} Save new shortcut\n"
    printf "  ${DIM_WHITE}   [--expires <epoch>]            ${RESET} Optional expiration\n"
    printf "  ${DIM_WHITE}to --rm,  -r <keyword>            ${RESET} Remove existing shortcut\n"
    printf "  ${DIM_WHITE}to --list, -l                     ${RESET} List all shortcuts\n"
    printf "  ${DIM_WHITE}to --print-path, -p <keyword>     ${RESET} Print stored path only\n"
    printf "  ${DIM_WHITE}to --code, -c <keyword>           ${RESET} Open in VSCode after navigation\n"
    printf "  ${DIM_WHITE}to --help, -h                     ${RESET} Show this help\n\n"

    printf "${MAGENTA}Options:${RESET}\n"
    printf "  ${BOLD_CYAN}keyword                        ${RESET}    Shortcut name\n"
    printf "  ${BOLD_CYAN}--add, -a                      ${RESET}    Add new shortcut\n"
    printf "  ${BOLD_CYAN}--rm, -r                       ${RESET}    Remove shortcut\n"
    printf "  ${BOLD_CYAN}--list, -l                     ${RESET}    List shortcuts\n"
    printf "  ${BOLD_CYAN}--print-path, -p               ${RESET}    Print path only\n"
    printf "  ${BOLD_CYAN}--code, -c                     ${RESET}    Open in VSCode\n"
    printf "  ${BOLD_CYAN}--expires <epoch>              ${RESET}    Expiration timestamp\n"
    printf "  ${BOLD_CYAN}--help, -h                     ${RESET}    Show help\n"
}

# List all saved shortcuts
function ListShortcuts {
    CleanExpiredShortcuts
    if [ ! -s "${CONFIG_FILE}" ]; then
        printf "${BOLD_RED}No shortcuts saved.${RESET}\n"
        return
    fi

    while IFS='=' read -r keyword value || [ -n "$keyword" ]; do
        local path="${value%%|*}"
        printf "${BOLD_CYAN}%s${RESET} → ${DIM_WHITE}%s${RESET}\n" "$keyword" "$path"
    done <"${CONFIG_FILE}"
}

# Add a new shortcut
function AddShortcut {
    local keyword="$1"
    local targetPath="$2"
    local expires="$3"

    if [ -z "${keyword}" ] || [ -z "${targetPath}" ]; then
        printf "${BOLD_RED}Usage: to --add <keyword> <path> [--expires <epoch>]${RESET}\n"
        return
    fi

    if [ ! -e "${targetPath}" ]; then
        printf "${BOLD_RED}Error: Path '%s' does not exist.${RESET}\n" "${targetPath}"
        return
    elif [ ! -d "${targetPath}" ]; then
        printf "${BOLD_RED}Error: Path '%s' exists but is not a directory.${RESET}\n" "${targetPath}"
        return
    fi

    local absPath
    absPath=$(cd "${targetPath}" && pwd)

    if grep -q "^${keyword}=" "${CONFIG_FILE}" 2>/dev/null; then
        printf "${BOLD_RED}Error: Keyword '%s' already exists.${RESET}\n" "${keyword}"
        return
    fi

    local record="${keyword}=${absPath}"
    if [ -n "${expires}" ]; then
        if [[ ! "${expires}" =~ ^[0-9]+$ ]]; then
            printf "${BOLD_RED}Error: expires must be epoch seconds.${RESET}\n"
            return
        fi
        record+="|${expires}"
    fi
    printf '%s\n' "${record}" >>"${CONFIG_FILE}"
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
    CleanExpiredShortcuts
    local input="$1"

    if [ -z "${input}" ]; then
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

    # exact match
    if grep -q "^${input}=" "${CONFIG_FILE}" 2>/dev/null; then
        local basePath
        basePath=$(grep "^${input}=" "${CONFIG_FILE}" | cut -d'=' -f2-)
        basePath="${basePath%%|*}"
        cd "${basePath}" && {
            printf "${GREEN}Changed directory to ${DIM_WHITE}%s${RESET}\n" "${basePath}"
            if [ "$runCode" -eq 1 ]; then code .; fi
        }
        return
    fi

    # split input into parts by '/'
    local -a parts
    parts=("${(@s:/:)input}")
    # build prefix candidates in descending length (Zsh arrays start at 1)
    local -a prefixes
    local len=${#parts[@]}
    for ((i=len; i>=1; i--)); do
        local prefix="${parts[1]}"
        for ((j=2; j<=i; j++)); do
            prefix+="/${parts[j]}"
        done
        prefixes+=("${prefix}")
    done

    # try each prefix as a keyword
    for prefix in "${prefixes[@]}"; do
        if grep -q "^${prefix}=" "${CONFIG_FILE}" 2>/dev/null; then
            local basePath remainder targetPath
            basePath=$(grep "^${prefix}=" "${CONFIG_FILE}" | cut -d'=' -f2-)
            basePath="${basePath%%|*}"
            remainder="${input#${prefix}}"
            remainder="${remainder#/}"
            targetPath="${basePath}"
            if [ -n "${remainder}" ]; then
                targetPath+="/${remainder}"
            fi
            if [ -d "${targetPath}" ]; then
                cd "${targetPath}" && {
                    printf "${GREEN}Changed directory to ${DIM_WHITE}%s${RESET}\n" "${targetPath}"
                    if [ "$runCode" -eq 1 ]; then code .; fi
                }
                return
            fi
        fi
    done

    printf "${BOLD_RED}Error: Shortcut or path '%s' not found.${RESET}\n" "${input}" >&2
}

# Main entrypoint
function to {
    if [ ! -f "${CONFIG_FILE}" ]; then
        touch "${CONFIG_FILE}"
    fi

    local runCode=0
    local printPath=0
    local action=""
    local addKeyword=""
    local targetPath=""
    local expiresArg=""
    local removeKeyword=""
    local positional=()

    # parse flags in any position
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--code)
                runCode=1
                shift
                ;;
            -p|--print-path)
                printPath=1
                shift
                ;;
            --help|-h)
                action="help"
                shift
                ;;
            --list|-l)
                action="list"
                shift
                ;;
            --add|-a)
                action="add"
                shift
                addKeyword="$1"
                targetPath="$2"
                shift 2
                ;;
            --expires)
                expiresArg="$2"
                shift 2
                ;;
            --rm|-r)
                action="remove"
                shift
                removeKeyword="$1"
                shift
                ;;
            *)
                positional+=("$1")
                shift
                ;;
        esac
    done

    if [[ $printPath -eq 1 ]]; then
        CleanExpiredShortcuts
        # handle print-path action
        if [ -z "${positional[1]}" ]; then
            printf "${BOLD_RED}Usage: to -p <keyword>[/subdir]${RESET}\n" >&2
            return 1
        fi
        # reuse existing logic from --print-path section
        local input="${positional[1]}"
        # exact match
        local pathLine
        if pathLine=$(grep -m1 "^${input}=" "${CONFIG_FILE}" 2>/dev/null); then
            printf "%s\n" "${pathLine#*=}" | cut -d'|' -f1
            return
        fi
        # prefix-match logic
        # (copy the prefix-match block from original --print-path code)
        parts=("${(@s:/:)input}")
        prefixes=()
        len=${#parts[@]}
        for ((i=len; i>=1; i--)); do
            prefix="${parts[1]}"
            for ((j=2; j<=i; j++)); do
                prefix+="/${parts[j]}"
            done
            prefixes+=("${prefix}")
        done
        for prefix in "${prefixes[@]}"; do
            if pathLine=$(grep -m1 "^${prefix}=" "${CONFIG_FILE}" 2>/dev/null); then
                basePath="${pathLine#*=}"
                basePath="${basePath%%|*}"
                remainder="${input#${prefix}}"
                remainder="${remainder#/}"
                target="${basePath}"
                if [ -n "${remainder}" ]; then
                    target+="/${remainder}"
                fi
                printf "%s\n" "${target}"
                return
            fi
        done
        printf "${BOLD_RED}Error: Shortcut or path '%s' not found.${RESET}\n" "${input}" >&2
        return 1
    fi

    case "$action" in
        help)
            To_ShowHelp
            ;;
        list)
            ListShortcuts
            ;;
        add)
            AddShortcut "$addKeyword" "$targetPath" "$expiresArg"
            ;;
        remove)
            RemoveShortcut "$removeKeyword"
            ;;
        *)
            # default to jump, passing first positional as input
            JumpToShortcut "${positional[1]}"
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
            compadd -- --help -h --list -l --add -a --rm -r --expires
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
