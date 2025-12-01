# Persistent Directory Shortcuts – `to` command

: "${TO_CONFIG_FILE:=${HOME}/.to_dirs}"
: "${TO_CONFIG_META_FILE:=${HOME}/.to_dirs_meta}"
: "${TO_USER_CONFIG_FILE:=${HOME}/.to_zsh_config}"
: "${TO_RECENT_FILE:=${HOME}/.to_dirs_recent}"

function CleanupExpiredShortcuts {

    local config_file
    local config_meta_file

    config_file="${1:-${TO_CONFIG_FILE}}"
    config_meta_file="${2:-${TO_CONFIG_META_FILE}}"

    if [ ! -f "${config_file}" ]; then
        return
    fi

    local now
    local tmpcfg
    local tmpmeta
    local storedPath

    now=$(date +%s)
    tmpcfg="${config_file}.tmp"
    tmpmeta="${config_meta_file}.tmp"

    : >"${tmpcfg}"
    : >"${tmpmeta}" 2>/dev/null || true

    while IFS='=' read -r key storedPath || [ -n "$key" ]; do

        local expiry=""

        if [ -f "${config_meta_file}" ]; then
            expiry=$(grep -m1 "^${key}=" "${config_meta_file}" | cut -d'=' -f2-)
        fi

        if [ -n "$expiry" ] && [ "$expiry" -le "$now" ]; then
            continue
        fi

        printf '%s=%s\n' "$key" "$storedPath" >>"${tmpcfg}"

        if [ -n "$expiry" ]; then
            printf '%s=%s\n' "$key" "$expiry" >>"${tmpmeta}"
        fi

    done <"${config_file}"

    mv "${tmpcfg}" "${config_file}"

    if [ -f "${tmpmeta}" ]; then
        mv "${tmpmeta}" "${config_meta_file}"
    fi
}

function LoadUserConfig {

    local user_config_file
    local sort_order="alpha"

    user_config_file="${1:-${TO_USER_CONFIG_FILE}}"

    if [ -f "${user_config_file}" ]; then
        while IFS='=' read -r key val || [ -n "$key" ]; do

            if [ "$key" = "sort_order" ]; then
                sort_order="$val"
            fi

        done <"${user_config_file}"
    fi

    printf '%s\n' "$sort_order"
}

function GetSortedKeywords {

    local config_file
    local config_meta_file
    local user_config_file
    local recent_file
    local sort_order

    config_file="${1:-${TO_CONFIG_FILE}}"
    config_meta_file="${2:-${TO_CONFIG_META_FILE}}"
    user_config_file="${3:-${TO_USER_CONFIG_FILE}}"
    recent_file="${4:-${TO_RECENT_FILE}}"
    sort_order=$(LoadUserConfig "${user_config_file}")

    CleanupExpiredShortcuts "${config_file}" "${config_meta_file}"

    if [ ! -f "${config_file}" ]; then
        return
    fi

    local key
    local storedPath
    local -a keys

    while IFS='=' read -r key storedPath || [ -n "$key" ]; do
        keys+=("$key")
    done <"${config_file}"

    case "$sort_order" in
        alpha)
            local -a sort_cmd

            if sort -V </dev/null 2>/dev/null; then
                sort_cmd=(sort -V)
            elif command -v gsort >/dev/null 2>&1 && gsort -V </dev/null 2>/dev/null; then
                sort_cmd=(gsort -V)
            else
                sort_cmd=(sort)
            fi

            keys=($(printf '%s\n' "${keys[@]}" | "${sort_cmd[@]}"))
            ;;
        recent)
            if [ -f "${recent_file}" ]; then
                keys=($(for k in "${keys[@]}"; do
                            ts=$(grep -m1 "^${k}=" "${recent_file}" | cut -d'=' -f2)
                            echo "${ts:-0} ${k}"
                        done | sort -k1,1nr | awk '{print $2}'))
            fi
            ;;
    esac

    printf '%s\n' "${keys[@]}"
}

# Main entrypoint
function to {

    # color codes (only define if not already set)
    local ESC="\033"
    local RESET="${ESC}[0m"
    local BOLD_CYAN="${ESC}[1;36m"
    local DIM_WHITE="${ESC}[2;37m"
    local DIM_BLUE="${ESC}[2;34m"
    local GREEN="${ESC}[0;32m"
    local BOLD_RED="${ESC}[1;31m"
    local YELLOW="${ESC}[0;33m"
    local MAGENTA="${ESC}[0;35m"

    local CONFIG_FILE="${HOME}/.to_dirs"
    local CONFIG_META_FILE="${HOME}/.to_dirs_meta"
    local USER_CONFIG_FILE="${HOME}/.to_zsh_config"
    local RECENT_FILE="${HOME}/.to_dirs_recent"

    # Helpers
    # ---------

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

        local tmp="${USER_CONFIG_FILE}.tmp"
        [ -f "${USER_CONFIG_FILE}" ] && grep -v '^sort_order=' "${USER_CONFIG_FILE}" >"${tmp}" || : >"${tmp}"
        printf 'sort_order=%s\n' "$mode" >>"${tmp}"
        mv "${tmp}" "${USER_CONFIG_FILE}"
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
        printf "  ${DIM_WHITE}%-55s${RESET}%s\n" "to --cursor, -c <keyword>" "Open in Cursor after navigation"
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
        printf "  ${BOLD_CYAN}%-30s${RESET}%s\n" "--cursor, -c" "Open in Cursor"
        printf "  ${BOLD_CYAN}%-30s${RESET}%s\n" "--no-create" "Disable path creation on jump"
        printf "  ${BOLD_CYAN}%-30s${RESET}%s\n" "--sort, -s" "Set sorting mode"
        printf "  ${BOLD_CYAN}%-30s${RESET}%s\n" "--help, -h" "Show help"

        DisplaySavedShortcuts
        local currentSort
        currentSort=$(LoadUserConfig "${USER_CONFIG_FILE}")
        printf "\nCurrent sorting mode: %s (from %s)\n" "$currentSort" "$USER_CONFIG_FILE"
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
        done < <(GetSortedKeywords "${CONFIG_FILE}" "${CONFIG_META_FILE}" "${USER_CONFIG_FILE}" "${RECENT_FILE}")
    }

    # Display saved shortcuts in a 3-column layout
    function DisplaySavedShortcuts {
        [ -r "${CONFIG_FILE}" ] || return

        local total shown cols rows maxlen idx key width i colsIndex
        local -a sorted

        sorted=($(GetSortedKeywords "${CONFIG_FILE}" "${CONFIG_META_FILE}" "${USER_CONFIG_FILE}" "${RECENT_FILE}"))
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
                if [ "$runCursor" -eq 1 ]; then cursor .; fi
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
                        if [ "$runCursor" -eq 1 ]; then cursor .; fi
                    }
                    UpdateRecentUsage "${prefix}"
                    return
                elif [ "$create" -eq 1 ]; then
                    if mkdir -p "${targetPath}" && cd "${targetPath}"; then
                        printf "${GREEN}Created and changed directory to ${DIM_WHITE}%s${RESET}\n" "${targetPath}"
                        if [ "$runCursor" -eq 1 ]; then cursor .; fi
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
    # Initialize config files if they don't exist
    if [ ! -f "${CONFIG_FILE}" ]; then
        touch "${CONFIG_FILE}"
    fi
    if [ ! -f "${CONFIG_META_FILE}" ]; then
        : >"${CONFIG_META_FILE}"
    fi
    if [ ! -f "${RECENT_FILE}" ]; then
        : >"${RECENT_FILE}"
    fi
    CleanupExpiredShortcuts "${CONFIG_FILE}" "${CONFIG_META_FILE}"

    local runCursor=0
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
            -c|--cursor)
                runCursor=1
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
        SetSortOrder "$newSortMode" || {
            unset -f ListShortcuts AddShortcut AddBulkShortcuts CopyShortcut RemoveShortcut JumpToShortcut
            return 1
        }
    fi

    if [[ $printPath -eq 1 ]]; then
        # handle print-path action
        if [ -z "${positional[1]}" ]; then
            printf "${BOLD_RED}Usage: to -p <keyword>[/subdir]${RESET}\n" >&2
            unset -f ListShortcuts AddShortcut AddBulkShortcuts CopyShortcut RemoveShortcut JumpToShortcut
            return 1
        fi
        # reuse existing logic from --print-path section
        local input="${positional[1]}"
        # exact match
        local pathLine
        if pathLine=$(grep -m1 "^${input}=" "${CONFIG_FILE}" 2>/dev/null); then
            printf "%s\n" "${pathLine#*=}"
            unset -f ListShortcuts AddShortcut AddBulkShortcuts CopyShortcut RemoveShortcut JumpToShortcut
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
                unset -f ListShortcuts AddShortcut AddBulkShortcuts CopyShortcut RemoveShortcut JumpToShortcut
                return
            fi
        done
        printf "${BOLD_RED}Error: Shortcut or path '%s' not found.${RESET}\n" "${input}" >&2
        unset -f ListShortcuts AddShortcut AddBulkShortcuts CopyShortcut RemoveShortcut JumpToShortcut
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

    # cleanup helpers
    unset -f ListShortcuts AddShortcut AddBulkShortcuts CopyShortcut RemoveShortcut JumpToShortcut
}

# Zsh completion for `to`
if [[ -n $ZSH_VERSION ]]; then

    _to() {

        local context state line
        typeset -A opt_args
        _arguments -s -C \
            '(-h --help)'{-h,--help}'[show help]' \
            '(-l --list)'{-l,--list}'[list shortcuts]' \
            '(-c --cursor)'{-c,--cursor}'[open in Cursor]' \
            '(-p --print-path)'{-p,--print-path}'[print stored path]:keyword:->keywords' \
            '(-a --add)'{-a,--add}'[add shortcut]:keyword:->keywords :path:_files -/' \
            '--add-bulk[add shortcuts from pattern]:pattern:' \
            '--copy[copy existing shortcut]:existing keyword:->keywords :new:' \
            '--expire[expiration timestamp]:timestamp:' \
            '--no-create[do not create missing directories]' \
            '(-s --sort)'{-s,--sort}'[set sorting mode]:mode:(added alpha recent)' \
            '(-r --rm)'{-r,--rm}'[remove shortcut]:keyword:->keywords' \
            '*:keyword:->keywords' && return

        local completionConfigFile
        completionConfigFile="${TO_CONFIG_FILE:-${HOME}/.to_dirs}"

        case $state in
        keywords)
            local cur=${words[CURRENT]}
            if [[ $cur == */* ]]; then
                local key=${cur%%/*}
                local rest=${cur#*/}
                local base
                base=$(grep -m1 "^${key}=" "${completionConfigFile}" 2>/dev/null | cut -d'=' -f2-)
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
