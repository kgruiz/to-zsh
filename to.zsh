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
CONFIG_META_FILE="${HOME}/.to_dirs_meta"
USER_CONFIG_FILE="${HOME}/.to_zsh_config"
RECENT_FILE="${HOME}/.to_dirs_recent"
USER_SORT_ORDER="added"

# Remove expired shortcuts from storage
function CleanupExpiredShortcuts {
    [ -f "${CONFIG_FILE}" ] || return
    local now tmpcfg tmpmeta storedPath
    now=$(date +%s)
    tmpcfg="${CONFIG_FILE}.tmp"
    tmpmeta="${CONFIG_META_FILE}.tmp"
    : >"${tmpcfg}"
    : >"${tmpmeta}" 2>/dev/null || true
    while IFS='=' read -r key storedPath || [ -n "$key" ]; do
        local expiry=""
        if [ -f "${CONFIG_META_FILE}" ]; then
            expiry=$(grep -m1 "^${key}=" "${CONFIG_META_FILE}" | cut -d'=' -f2-)
        fi
        if [ -n "$expiry" ] && [ "$expiry" -le "$now" ]; then
            continue
        fi
        printf '%s=%s\n' "$key" "$storedPath" >>"${tmpcfg}"
        if [ -n "$expiry" ]; then
            printf '%s=%s\n' "$key" "$expiry" >>"${tmpmeta}"
        fi
    done <"${CONFIG_FILE}"
    mv "${tmpcfg}" "${CONFIG_FILE}"
    if [ -f "${tmpmeta}" ]; then
        mv "${tmpmeta}" "${CONFIG_META_FILE}"
    fi
}

# Load user preferences
function LoadUserConfig {
    USER_SORT_ORDER="added"
    if [ -f "${USER_CONFIG_FILE}" ]; then
        while IFS='=' read -r key val || [ -n "$key" ]; do
            case "$key" in
                sort_order)
                    USER_SORT_ORDER="$val"
                    ;;
            esac
        done <"${USER_CONFIG_FILE}"
    fi
}

# Persist new sorting mode to the user config
function SetSortOrder {
    local mode="$1"
    case "$mode" in
        added|alpha|recent)
            ;;
        *)
            printf "${BOLD_RED}Invalid sort mode '%s'. Use added, alpha, or recent.${RESET}\n" "$mode" >&2
            return 1
            ;;
    esac

    USER_SORT_ORDER="$mode"
    local tmp="${USER_CONFIG_FILE}.tmp"
    [ -f "${USER_CONFIG_FILE}" ] && grep -v '^sort_order=' "${USER_CONFIG_FILE}" >"${tmp}" || : >"${tmp}"
    printf 'sort_order=%s\n' "$mode" >>"${tmp}"
    mv "${tmp}" "${USER_CONFIG_FILE}"
}

# Return saved keywords sorted per user preference
function GetSortedKeywords {
    LoadUserConfig
    CleanupExpiredShortcuts
    local key storedPath
    local -a keys
    while IFS='=' read -r key storedPath || [ -n "$key" ]; do
        keys+=("$key")
    done <"${CONFIG_FILE}"
    case "$USER_SORT_ORDER" in
        alpha)
            keys=($(printf '%s\n' "${keys[@]}" | sort))
            ;;
        recent)
            if [ -f "${RECENT_FILE}" ]; then
                keys=($(for k in "${keys[@]}"; do
                            ts=$(grep -m1 "^${k}=" "${RECENT_FILE}" | cut -d'=' -f2)
                            echo "${ts:-0} ${k}"
                        done | sort -k1,1nr | awk '{print $2}'))
            fi
            ;;
    esac
    printf '%s\n' "${keys[@]}"
}

# Update timestamp for most recently used keywords
function UpdateRecentUsage {
    local keyword="$1"
    local now
    now=$(date +%s)
    [ -f "${RECENT_FILE}" ] || : >"${RECENT_FILE}"
    if grep -q "^${keyword}=" "${RECENT_FILE}" 2>/dev/null; then
        grep -v "^${keyword}=" "${RECENT_FILE}" >"${RECENT_FILE}.tmp" && mv "${RECENT_FILE}.tmp" "${RECENT_FILE}"
    fi
    printf '%s=%s\n' "$keyword" "$now" >>"${RECENT_FILE}"
}

# Show usage/help
function To_ShowHelp {
    printf "${YELLOW}to - Persistent Directory Shortcuts${RESET}\n\n"

    printf "${MAGENTA}Usage:${RESET}\n"
    printf "  ${DIM_WHITE}%-55s${RESET}%s\n" "to <keyword>" "Navigate to saved shortcut"
    printf "  ${DIM_WHITE}%-55s${RESET}%s\n" "to --add, -a <keyword> <path> [--expire <timestamp>]" "Save new shortcut"
    printf "  ${DIM_WHITE}%-55s${RESET}%s\n" "to --add <path> [--expire <timestamp>]" "Save shortcut using directory name as keyword"
    printf "  ${DIM_WHITE}%-55s${RESET}%s\n" "to --add-bulk <pattern>" "Add shortcuts for each matching directory"
    printf "  ${DIM_WHITE}%-55s${RESET}%s\n" "to --copy <existing> <new>" "Duplicate shortcut"
    printf "  ${DIM_WHITE}%-55s${RESET}%s\n" "to --rm, -r <keyword>" "Remove existing shortcut"
    printf "  ${DIM_WHITE}%-55s${RESET}%s\n" "to --list, -l" "List all shortcuts"
    printf "  ${DIM_WHITE}%-55s${RESET}%s\n" "to --print-path, -p <keyword>" "Print stored path only"
    printf "  ${DIM_WHITE}%-55s${RESET}%s\n" "to --code, -c <keyword>" "Open in VSCode after navigation"
    printf "  ${DIM_WHITE}%-55s${RESET}%s\n" "to --no-create" "Do not create nested path on jump"
    printf "  ${DIM_WHITE}%-55s${RESET}%s\n" "to --sort, -s <mode>" "Set sorting mode (added | alpha | recent)"
    printf "  ${DIM_WHITE}%-55s${RESET}%s\n\n" "to --help, -h" "Show this help"

    printf "${MAGENTA}Options:${RESET}\n"
    printf "  ${BOLD_CYAN}%-30s${RESET}%s\n" "keyword" "Shortcut name"
    printf "  ${BOLD_CYAN}%-30s${RESET}%s\n" "--add, -a" "Add new shortcut"
    printf "  ${BOLD_CYAN}%-30s${RESET}%s\n" "--add-bulk <pattern>" "Add shortcuts from pattern"
    printf "  ${BOLD_CYAN}%-30s${RESET}%s\n" "--copy <existing> <new>" "Duplicate shortcut"
    printf "  ${BOLD_CYAN}%-30s${RESET}%s\n" "--rm, -r" "Remove shortcut"
    printf "  ${BOLD_CYAN}%-30s${RESET}%s\n" "--list, -l" "List shortcuts"
    printf "  ${BOLD_CYAN}%-30s${RESET}%s\n" "--print-path, -p" "Print path only"
    printf "  ${BOLD_CYAN}%-30s${RESET}%s\n" "--expire <ts>" "Set expiration epoch for shortcut"
    printf "  ${BOLD_CYAN}%-30s${RESET}%s\n" "--code, -c" "Open in VSCode"
    printf "  ${BOLD_CYAN}%-30s${RESET}%s\n" "--no-create" "Disable path creation on jump"
    printf "  ${BOLD_CYAN}%-30s${RESET}%s\n" "--sort, -s" "Set sorting mode"
    printf "  ${BOLD_CYAN}%-30s${RESET}%s\n" "--help, -h" "Show help"

    DisplaySavedShortcuts
    LoadUserConfig
    printf "\nCurrent sorting mode: %s (from %s)\n" "$USER_SORT_ORDER" "$USER_CONFIG_FILE"
}

# List all saved shortcuts
function ListShortcuts {
    if [ ! -s "${CONFIG_FILE}" ]; then
        printf "${BOLD_RED}No shortcuts saved.${RESET}\n"
        return
    fi

    local keyword targetPath
    while IFS= read -r keyword; do
        targetPath=$(grep -m1 "^${keyword}=" "${CONFIG_FILE}" | cut -d'=' -f2-)
        printf "${BOLD_CYAN}%s${RESET} → ${DIM_WHITE}%s${RESET}\n" "$keyword" "$targetPath"
    done < <(GetSortedKeywords)
}

# Display saved shortcuts in a 3-column layout
function DisplaySavedShortcuts {
    [ -r "${CONFIG_FILE}" ] || return

    local total shown cols rows maxlen idx key width i colsIndex
    local -a sorted

    sorted=($(GetSortedKeywords))
    total=${#sorted[@]}
    shown=$(( total < 30 ? total : 30 ))

    maxlen=0
    for ((idx=1; idx<=shown; idx++)); do
        key="${sorted[idx]}"
        if [ ${#key} -gt "${maxlen}" ]; then
            maxlen=${#key}
        fi
    done
    width=$((maxlen + 2))

    cols=3
    rows=$(( (shown + cols - 1) / cols ))

    if [ "${total}" -le 30 ]; then
        printf "\n${MAGENTA}Saved shortcuts:${RESET}\n"
    else
        printf "\n${MAGENTA}Saved shortcuts (showing %d of %d):${RESET}\n" "${shown}" "${total}"
    fi

    for ((i=1; i<=rows; i++)); do
        for ((colsIndex=1; colsIndex<=cols; colsIndex++)); do
            idx=$(( (colsIndex - 1) * rows + i ))
            if [ ${idx} -le ${shown} ]; then
                key="${sorted[idx]}"
                printf "  ${YELLOW}%2d${RESET}. ${BOLD_CYAN}%-${width}s${RESET}" "${idx}" "$key"
            fi
        done
        printf "\n"
    done

    if [ "${total}" -gt "${shown}" ]; then
        printf "  … and %d more\n" "$((total - shown))"
    fi
}

# Add a new shortcut
function AddShortcut {
    local keyword="$1"
    local targetPath="$2"
    local expire="$3"

    # When only one argument is provided, treat it as the path and derive
    # the keyword from the final directory component.
    if [ -z "${targetPath}" ]; then
        targetPath="$keyword"
        keyword="$(basename -- "${targetPath}")"
    fi

    if [ -z "${keyword}" ] || [ -z "${targetPath}" ]; then
        printf "${BOLD_RED}Usage: to --add <keyword> <path>${RESET}\n"
        return 1
    fi

    if [ ! -e "${targetPath}" ]; then
        printf "${BOLD_RED}Error: Path '%s' does not exist.${RESET}\n" "${targetPath}"
        return 1
    elif [ ! -d "${targetPath}" ]; then
        printf "${BOLD_RED}Error: Path '%s' exists but is not a directory.${RESET}\n" "${targetPath}"
        return 1
    fi

    local absPath
    absPath=$(cd "${targetPath}" && pwd)

    if grep -q "^${keyword}=" "${CONFIG_FILE}" 2>/dev/null; then
        printf "${BOLD_RED}Error: Keyword '%s' already exists.${RESET}\n" "${keyword}"
        return 1
    fi

    printf '%s\n' "${keyword}=${absPath}" >>"${CONFIG_FILE}"
    if [ -n "${expire}" ]; then
        printf '%s\n' "${keyword}=${expire}" >>"${CONFIG_META_FILE}"
        printf "${GREEN}Added ${BOLD_CYAN}%s${RESET}${GREEN} → ${DIM_WHITE}%s${RESET}${GREEN} (expires %s)${RESET}\n" "${keyword}" "${absPath}" "${expire}"
    else
        if grep -q "^${keyword}=" "${CONFIG_META_FILE}" 2>/dev/null; then
            grep -v "^${keyword}=" "${CONFIG_META_FILE}" >"${CONFIG_META_FILE}.tmp" && mv "${CONFIG_META_FILE}.tmp" "${CONFIG_META_FILE}"
        fi
        printf "${GREEN}Added ${BOLD_CYAN}%s${RESET}${GREEN} → ${DIM_WHITE}%s${RESET}\n" "${keyword}" "${absPath}"
    fi
}

# Add multiple shortcuts from a pattern
function AddBulkShortcuts {
    local pattern="$1"

    if [ -z "${pattern}" ]; then
        printf "${BOLD_RED}Usage: to --add-bulk <pattern>${RESET}\n"
        return
    fi

    local -a dirs
    dirs=(${~pattern})

    if [[ ${#dirs[@]} -eq 0 ]]; then
        printf "${BOLD_RED}No directories match pattern '%s'.${RESET}\n" "${pattern}"
        return
    fi

    local dir
    for dir in "${dirs[@]}"; do
        if [ -d "${dir}" ]; then
            AddShortcut "${dir}"
        fi
    done
}

# Copy an existing shortcut to a new keyword or path
function CopyShortcut {
    local existing="$1"
    local new="$2"

    if [ -z "${existing}" ] || [ -z "${new}" ]; then
        printf "${BOLD_RED}Usage: to --copy <existing> <new>${RESET}\n"
        return
    fi

    if ! grep -q "^${existing}=" "${CONFIG_FILE}" 2>/dev/null; then
        printf "${BOLD_RED}Error: Keyword '%s' not found.${RESET}\n" "${existing}"
        return
    fi

    local srcPath destKey destPath
    srcPath=$(grep -m1 "^${existing}=" "${CONFIG_FILE}" | cut -d'=' -f2-)

    if [ -d "${new}" ] || [[ "${new}" == /* ]]; then
        destPath="${new}"
        destKey="$(basename -- "${destPath}")"
    else
        destKey="${new}"
        destPath="${srcPath}"
    fi

    if grep -q "^${destKey}=" "${CONFIG_FILE}" 2>/dev/null; then
        printf "${BOLD_RED}Error: Keyword '%s' already exists.${RESET}\n" "${destKey}"
        return
    fi

    AddShortcut "${destKey}" "${destPath}"
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
    if [ -f "${CONFIG_META_FILE}" ]; then
        grep -v "^${keyword}=" "${CONFIG_META_FILE}" >"${CONFIG_META_FILE}.tmp" && mv "${CONFIG_META_FILE}.tmp" "${CONFIG_META_FILE}"
    fi
    printf "${GREEN}Removed ${BOLD_CYAN}%s${RESET}${GREEN}.${RESET}\n" "${keyword}"
}

# Jump to a saved directory
function JumpToShortcut {
    local input="$1"
    local create="${2:-1}"

    if [ -z "${input}" ]; then
        To_ShowHelp
        return
    fi

    # exact match
    if grep -q "^${input}=" "${CONFIG_FILE}" 2>/dev/null; then
        local basePath
        basePath=$(grep "^${input}=" "${CONFIG_FILE}" | cut -d'=' -f2-)
        cd "${basePath}" && {
            printf "${GREEN}Changed directory to ${DIM_WHITE}%s${RESET}\n" "${basePath}"
            if [ "$runCode" -eq 1 ]; then code .; fi
        }
        UpdateRecentUsage "${input}"
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
                UpdateRecentUsage "${prefix}"
                return
            elif [ "$create" -eq 1 ]; then
                if mkdir -p "${targetPath}" && cd "${targetPath}"; then
                    printf "${GREEN}Created and changed directory to ${DIM_WHITE}%s${RESET}\n" "${targetPath}"
                    if [ "$runCode" -eq 1 ]; then code .; fi
                    UpdateRecentUsage "${prefix}"
                    return
                else
                    printf "${BOLD_RED}Error: Failed to create '%s'.${RESET}\n" "${targetPath}" >&2
                    return 1
                fi
            else
                printf "${BOLD_RED}Error: Resolved path '%s' does not exist.${RESET}\n" "${targetPath}" >&2
                return 1
            fi
        fi
    done

    printf "${BOLD_RED}Error: Shortcut or path '%s' not found.${RESET}\n" "${input}" >&2
    return 1
}

# Main entrypoint
function to {
    if [ ! -f "${CONFIG_FILE}" ]; then
        touch "${CONFIG_FILE}"
    fi
    if [ ! -f "${CONFIG_META_FILE}" ]; then
        : >"${CONFIG_META_FILE}"
    fi
    if [ ! -f "${RECENT_FILE}" ]; then
        : >"${RECENT_FILE}"
    fi
    CleanupExpiredShortcuts

    local runCode=0
    local printPath=0
    local createFlag=1
    local action=""
    local addKeyword=""
    local targetPath=""
    local expireTime=""
    local removeKeyword=""
    local bulkPattern=""
    local copyExisting=""
    local copyNew=""
    local newSortMode=""
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
                if [[ $# -ge 2 && $2 != -* ]]; then
                    targetPath="$2"
                    shift 2
                else
                    targetPath=""
                    shift 1
                fi
                ;;
            --add-bulk)
                action="add-bulk"
                shift
                bulkPattern="$1"
                shift
                ;;
            --copy)
                action="copy"
                shift
                copyExisting="$1"
                copyNew="$2"
                shift 2
                ;;
            --expire)
                expireTime="$2"
                shift 2
                ;;
            --no-create)
                createFlag=0
                shift
                ;;
            --sort|-s)
                newSortMode="$2"
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

    if [ -n "$newSortMode" ]; then
        SetSortOrder "$newSortMode" || return
    fi

    if [[ $printPath -eq 1 ]]; then
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
            printf "%s\n" "${pathLine#*=}"
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
            AddShortcut "$addKeyword" "$targetPath" "$expireTime"
            ;;
        add-bulk)
            AddBulkShortcuts "$bulkPattern"
            ;;
        copy)
            CopyShortcut "$copyExisting" "$copyNew"
            ;;
        remove)
            RemoveShortcut "$removeKeyword"
            ;;
        *)
            # default to jump, passing first positional as input
            JumpToShortcut "${positional[1]}" "$createFlag"
            ;;
    esac
}

# Zsh completion for `to`
if [[ -n $ZSH_VERSION ]]; then

    _to() {

        local context state line
        typeset -A opt_args
        _arguments -s -C \
            '(-h --help)'{-h,--help}'[show help]' \
            '(-l --list)'{-l,--list}'[list shortcuts]' \
            '(-c --code)'{-c,--code}'[open in VSCode]' \
            '(-p --print-path)'{-p,--print-path}'[print stored path]:keyword:->keywords' \
            '(-a --add)'{-a,--add}'[add shortcut]:keyword:->keywords :path:_files -/' \
            '--add-bulk[add shortcuts from pattern]:pattern:' \
            '--copy[copy existing shortcut]:existing keyword:->keywords :new:' \
            '--expire[expiration timestamp]:timestamp:' \
            '--no-create[do not create missing directories]' \
            '(-s --sort)'{-s,--sort}'[set sorting mode]:mode:(added alpha recent)' \
            '(-r --rm)'{-r,--rm}'[remove shortcut]:keyword:->keywords' \
            '*:keyword:->keywords' && return

        case $state in
        keywords)
            local cur=${words[CURRENT]}
            if [[ $cur == */* ]]; then
                local key=${cur%%/*}
                local rest=${cur#*/}
                local base
                base=$(grep -m1 "^${key}=" "${CONFIG_FILE}" 2>/dev/null | cut -d'=' -f2-)
                if [[ -n $base ]]; then
                    _path_files -W "$base" -/ "$rest"
                    return
                fi
            fi

            local -a keywords
            keywords=($(GetSortedKeywords))
            compadd -- $keywords
            ;;
        esac
    }
    compdef _to to
fi
