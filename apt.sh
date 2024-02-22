#!/bin/bash
set -euo pipefail

apt_update() {
    local n
    pacman -Sy
    if n=$(pacman -Quq | wc -l); then
        echo "$n packages can be upgraded. Run 'apt list --upgradable' to see them."
        if [ "${1:-}" = '--full-upgrade' ]; then
            apt_full-upgrade
        fi
    else
        echo 'All packages are up to date.'
    fi
}
apt_show() {
    pacman -Si "$@"
}
apt_download() {
    pacman -Swdd --noconfirm --cachedir . "$@"
}
apt_search() {
    local opts
    if [ "${1:-}" = '--names-only' ]; then
        shift
        opts='-Ss'
        if [ -t 1 ]; then
            opts="$opts --color always"
        fi
        pacman $opts | grep -EA 1 --no-group-separator "^\\S+/\\S*$1\\S* \\S*[[:digit:]]\\S+( \\S*\\(\\S+\\)\\S*)?( \\S*\\[installed\\]\\S*)?\$" || true
    else
        pacman -Ss "$1" || true
    fi
}
apt_list() {
    local opts
    case "${1:-}" in
        --installed)
            shift
            opts='-Q'
            ;;
        --auto-installed)
            shift
            opts='-Qd'
            ;;
        --manual-installed)
            shift
            opts='-Qe'
            ;;
        --removable)
            shift
            opts='-Qdt'
            ;;
        --upgradable)
            shift
            opts='-Qu'
            ;;
        *)
            opts='-Sl'
            ;;
    esac
    if [ $# = 0 ]; then
        pacman $opts || true
    else
        if [ -t 1 ]; then
            opts="$opts --color always"
        fi
        pacman $opts | grep -E "^(\\S+ )?\\S*$1\\S* \\S*[[:digit:]]\\S+( \\[installed\\])?\$" || true
    fi
}
apt_install() {
    local mark_auto opts
    if [ "$1" = '--mark-auto' ]; then
        shift
        mark_auto=true
    else
        mark_auto=false
    fi
    if [[ "$1" == *://* || -f "$1" ]]; then
        opts='-U'
    else
        opts='-S'
    fi
    pacman $opts --needed "$@"
    $mark_auto && apt_mark --auto "$@" || true
}
apt_reinstall() {
    local mark_auto opts
    if [ "$1" = '--mark-auto' ]; then
        shift
        mark_auto=true
    else
        mark_auto=false
    fi
    if [[ "$1" == *://* || -f "$1" ]]; then
        opts='-U'
    else
        opts='-S'
    fi
    pacman $opts "$@"
    $mark_auto && apt_mark --auto "$@" || true
}
apt_full-upgrade() {
    pacman -Su
}
apt_remove() {
    pacman -Rc "$@"
}
apt_autoremove() {
    if [ -n "${1:-}" ]; then
        pacman -Rcs "$@"
    elif list=$(pacman -Qqdt); then
        pacman -Rcs $(tr '\n' ' ' <<<"$list")
    fi
}
apt_clean() {
    pacman -Scc --noconfirm
}
apt_autoclean() {
    pacman -Sc --noconfirm
}
apt_mark() {
    case "$1" in
        --auto)
            shift
            pacman -D --asdeps "$@"
            ;;
        --manual)
            shift
            pacman -D --asexplicit "$@"
            ;;
        *)
            echo "Unknown option: $1" >&2
            return 1
            ;;
    esac
}
apt_-l() {
    pacman -Ql "$@"
}
apt_-s() {
    pacman -Qo "$@"
}
apt_-c() {
    mkdir -p /usr/local/share/bash-completion/completions
    {
        sed -nE '/^_apt.+/,/^}/p' $0
        echo "complete -F _apt apt"
    } >/usr/local/share/bash-completion/completions/apt
}
apt_-u() {
    local ret
    if curl --connect-timeout 10 -Lfo /usr/local/bin/.apt 'https://raw.githubusercontent.com/beavailable/apt.sh/main/apt.sh'; then
        mv /usr/local/bin/.apt /usr/local/bin/apt
        apt -c
    else
        ret=$?
        rm -f /usr/local/bin/.apt
        return $ret
    fi
}
apt_help() {
    echo "usage: $(basename $0) COMMAND [OPTIONS] [arguments]"
    echo
    echo 'COMMANDS:'
    echo '    update [OPTION]               update list of available packages'
    echo '        --full-upgrade'
    echo '    show PACKAGES                 show package details'
    echo '    download PACKAGES             download packages'
    echo '    search REGEX                  search for packages'
    echo '        --names-only'
    echo '    list [OPTION] [REGEX]         list packages'
    echo '        --auto-installed'
    echo '        --installed'
    echo '        --manual-installed'
    echo '        --removable'
    echo '        --upgradable'
    echo '    install [OPTION] PACKAGES     install packages'
    echo '        --mark-auto'
    echo '    reinstall [OPTION] PACKAGES   reinstall packages'
    echo '        --mark-auto'
    echo '    full-upgrade                  upgrade the system'
    echo '    remove PACKAGES               remove packages'
    echo '    autoremove [PACKAGES]         automatically remove all unused packages'
    echo '    clean                         remove all files from the cache'
    echo '    autoclean                     remove old packages from the cache'
    echo '    mark OPTION PACKAGES          mark packages as manually or automatically installed'
    echo '        --auto'
    echo '        --manual'
    echo '    -l PACKAGES                   list files owned by specific packages'
    echo '    -s FILES                      search for packages that own specific files'
    echo '    -c                            install the completion file'
    echo '    -u                            upgrade this tool from github'
    echo '    help                          show this help message'
}
_apt_complete_packages() {
    local opts
    if [[ "$cur" == -* ]]; then
        [ -z "$MINGW_PACKAGE_PREFIX" ] && return
        cur="$MINGW_PACKAGE_PREFIX$cur"
    fi
    if [ "${1:-}" = 'local' ]; then
        opts='-Qq'
    else
        opts='-Slq'
    fi
    COMPREPLY=($(compgen -W "$(pacman $opts)" -- "$cur"))
}
_apt() {
    local cur prev words cword
    _init_completion || return
    if [ "$cword" = 1 ]; then
        COMPREPLY=($(compgen -W '-c -l -s -u autoclean autoremove clean download full-upgrade help install list mark reinstall remove search show update' -- "$cur"))
    else
        case "${words[1]}" in
            update)
                if [ "$cword" = 2 ]; then
                    COMPREPLY=($(compgen -W '--full-upgrade' -- "$cur"))
                fi
                ;;
            show | download)
                _apt_complete_packages
                ;;
            search)
                if [ "$cword" = 2 ]; then
                    COMPREPLY=($(compgen -W '--names-only' -- "$cur"))
                fi
                ;;
            list)
                if [ "$cword" = 2 ]; then
                    COMPREPLY=($(compgen -W '--auto-installed --installed --manual-installed --removable --upgradable' -- "$cur"))
                fi
                ;;
            install | reinstall)
                if [ "$cword" = 2 ] && [[ "$cur" == --* ]]; then
                    COMPREPLY=($(compgen -W '--mark-auto' -- "$cur"))
                else
                    _apt_complete_packages
                fi
                ;;
            remove | autoremove | -l)
                _apt_complete_packages 'local'
                ;;
            mark)
                if [ "$cword" = 2 ] && [[ "$cur" == --* ]]; then
                    COMPREPLY=($(compgen -W '--auto --manual' -- "$cur"))
                else
                    _apt_complete_packages 'local'
                fi
                ;;
            \-s)
                _filedir
                ;;
        esac
    fi
}
main() {
    local cmd
    if cmd="apt_$1" && [ "$(type -t $cmd)" = 'function' ]; then
        shift
        $cmd "$@"
    else
        echo "Invalid operation $1" >&2
        return 1
    fi
}

main "$@"
