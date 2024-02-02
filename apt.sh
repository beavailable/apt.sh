#!/bin/bash
set -euo pipefail

apt_update() {
    local n
    pacman -Sy
    if n=$(pacman -Qu | wc -l); then
        echo "$n packages can be upgraded. Run 'apt list --upgradable' to see them."
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
    pacman -Ss "$@"
}
apt_list() {
    case "${1:-}" in
        '')
            pacman -Sl || true
            ;;
        --installed)
            pacman -Q || true
            ;;
        --auto-installed)
            pacman -Qd || true
            ;;
        --manual-installed)
            pacman -Qe || true
            ;;
        --removable)
            pacman -Qdt || true
            ;;
        --upgradable)
            pacman -Qu || true
            ;;
        *)
            echo "Unknown option: $1" >&2
            return 1
            ;;
    esac
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
    pacman -Rcn "$@"
}
apt_autoremove() {
    local list
    if [ -n "${1:-}" ]; then
        pacman -Rcsn "$@"
    elif list=$(pacman -Qqdt); then
        pacman -Rsn $(tr '\n' ' ' <<<"$list")
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
apt_completion() {
    mkdir -p /usr/local/share/bash-completion/completions
    {
        sed -nE '/^_apt.+/,/^}/p' $0
        echo "complete -F _apt apt"
    } >/usr/local/share/bash-completion/completions/apt
}
apt_help() {
    echo "usage: $(basename $0) COMMAND [OPTIONS] [arguments]"
    echo
    echo 'COMMANDS:'
    echo '    update                        update list of available packages'
    echo '    show PACKAGES                 show package details'
    echo '    download PACKAGES             download packages'
    echo '    search REGEX                  search packages'
    echo '    list [OPTION]                 list packages'
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
    echo '    completion                    install the completion file'
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
        COMPREPLY=($(compgen -W '-l -s autoclean autoremove clean completion download full-upgrade help install list mark reinstall remove search show update' -- "$cur"))
    else
        case "${words[1]}" in
            show | download)
                _apt_complete_packages
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
            remove | autoremove | \-l)
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
