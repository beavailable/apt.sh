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
        pacman $opts | sed -nE "/^\\S[^\\/]+\\/(\\S\\[[[:digit:]]+;[[:digit:]]+m)?(\\S+) .+\$/{h;s//\\2/;/$1/{g;p;n;p}}" || true
    else
        pacman -Ss "$1" || true
    fi
}
apt_list() {
    local opts e expr
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
        --hold)
            shift
            e=$'\e'
            if [ -t 1 ]; then
                expr="/^IgnorePkg\\s+= (.+)$/{s//\\1/;/\\S+/{s//$e[0;1m\\0$e[0m/g;s/ /\\n/g;p}}"
            else
                expr='/^IgnorePkg\s+= (.+)$/{s//\1/;s/ /\n/g;p}'
            fi
            if [ -z "${1:-}" ]; then
                sed -nE "$expr" /etc/pacman.conf
            else
                sed -nE "$expr" /etc/pacman.conf | sed -nE "/^(\\S\\[[[:digit:]]+;[[:digit:]]+m)?([^$e]+)(\\S\\[0m)?$/{h;s//\\2/;/$1/{g;p}}"
            fi
            return
            ;;
        *)
            opts='-Sl'
            ;;
    esac
    if [ -z "${1:-}" ]; then
        pacman $opts || true
    else
        if [ -t 1 ]; then
            opts="$opts --color always"
        fi
        pacman $opts | sed -nE "/^(\\S\\[[[:digit:]]+;[[:digit:]]+m)?((msys|ucrt64|clang64|clangarm64|clang32|mingw64|mingw32) )?(\\S\\[[[:digit:]]+;[[:digit:]]+m)?(\\S+) .+\$/{h;s//\\5/;/$1/{g;p}}" || true
    fi
}
apt_install() {
    local reinstall mark_auto opts
    if [ "$1" = '--reinstall' ]; then
        shift
        reinstall=true
    else
        reinstall=false
    fi
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
    if ! $reinstall; then
        opts="$opts --needed"
    fi
    pacman $opts "$@"
    $mark_auto && apt_mark --auto "$@" || true
}
apt_reinstall() {
    apt_install --reinstall "$@"
}
apt_full-upgrade() {
    pacman -Su
}
apt_remove() {
    local opts
    if [ "$1" == '--save-configurations' ]; then
        shift
        opts='-Rc'
    else
        opts='-Rcn'
    fi
    pacman $opts "$@"
}
apt_autoremove() {
    local opts list
    if [ "${1:-}" == '--save-configurations' ]; then
        shift
        opts='-Rcs'
    else
        opts='-Rcsn'
    fi
    if [ -n "${1:-}" ]; then
        pacman $opts "$@"
    elif list=$(pacman -Qqdt); then
        pacman $opts $(tr '\n' ' ' <<<"$list")
    fi
}
apt_autopurge() {
    apt_autoremove "$@"
}
apt_depends() {
    local opts
    if [ "$1" == '--recurse' ]; then
        shift
        opts='-s'
    else
        opts='-s -d 1'
    fi
    pactree $opts "$@"
}
apt_rdepends() {
    local opts
    if [ "$1" == '--recurse' ]; then
        shift
        opts='-sr'
    else
        opts='-sr -d 1'
    fi
    pactree $opts "$@"
}
apt_clean() {
    pacman -Scc --noconfirm
}
apt_autoclean() {
    pacman -Sc --noconfirm
}
apt_mark() {
    local content
    case "$1" in
        --auto)
            shift
            pacman -D --asdeps "$@"
            ;;
        --manual)
            shift
            pacman -D --asexplicit "$@"
            ;;
        --hold)
            shift
            [ -n "$1" ]
            content=$({ echo -n "$@" && sed -nE 's/^IgnorePkg\s+=(.+)$/\1/p' /etc/pacman.conf; } | tr ' ' '\n' | sort -Vu | tr '\n' ' ' | head -c -1)
            sed -i -E "s/^#?IgnorePkg\\s+=.*\$/IgnorePkg = $content/" /etc/pacman.conf
            ;;
        --unhold)
            shift
            [ -n "$1" ]
            for content in "$@"; do
                sed -i -E "s/^(IgnorePkg\\s+=.*)( $content)(( \\S+)*)\$/\\1\\3/" /etc/pacman.conf
            done
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
        echo 'complete -F _apt apt'
    } >/usr/local/share/bash-completion/completions/apt
}
apt_-u() {
    local tmp_name error_code
    tmp_name=$(mktemp)
    if curl --connect-timeout 10 -Lfo $tmp_name 'https://raw.githubusercontent.com/beavailable/apt.sh/main/apt.sh'; then
        mv $tmp_name /usr/local/bin/apt
        apt -c
    else
        error_code=$?
        rm -f $tmp_name
        return $error_code
    fi
}
apt_help() {
    echo "usage: $(basename $0) COMMAND [OPTION]... [ARG]..."
    echo
    echo 'COMMANDS:'
    echo '    update [OPTION]                   update list of available packages'
    echo '        --full-upgrade'
    echo '    show PACKAGE...                   show package details'
    echo '    download PACKAGE...               download packages'
    echo '    search [OPTION] REGEX             search for packages'
    echo '        --names-only'
    echo '    list [OPTION] [REGEX]             list packages'
    echo '        --auto-installed'
    echo '        --installed'
    echo '        --manual-installed'
    echo '        --removable'
    echo '        --upgradable'
    echo '        --hold'
    echo '    install [OPTION] PACKAGE...       install packages'
    echo '        --mark-auto'
    echo '    reinstall [OPTION] PACKAGE...     reinstall packages'
    echo '        --mark-auto'
    echo '    full-upgrade                      upgrade the system'
    echo '    remove PACKAGE...                 remove packages'
    echo '        --save-configurations'
    echo '    autoremove [PACKAGE]...           automatically remove all unused packages'
    echo '        --save-configurations'
    echo '    autopurge [PACKAGE]...            an alias for autoremove'
    echo '    depends [OPTION] PACKAGE          list packages that a package depends on'
    echo '        --recurse'
    echo '    rdepends [OPTION] PACKAGE         list packages that depend on a package'
    echo '        --recurse'
    echo '    clean                             remove all files from the cache'
    echo '    autoclean                         remove old packages from the cache'
    echo '    mark OPTION PACKAGE...            mark packages'
    echo '        --auto'
    echo '        --manual'
    echo '        --hold'
    echo '        --unhold'
    echo '    -l PACKAGE...                     list files owned by specific packages'
    echo '    -s FILE...                        search for packages that own specific files'
    echo '    -c                                install the completion file'
    echo '    -u                                upgrade this tool from github'
    echo '    help                              show this help message'
}
_apt_complete_packages() {
    local packages
    if [[ "$cur" == -* ]]; then
        [ -z "$MINGW_PACKAGE_PREFIX" ] && return
        cur="$MINGW_PACKAGE_PREFIX$cur"
    fi
    case "${1:-}" in
        local)
            packages=$(pacman -Qq)
            ;;
        hold)
            packages=$(apt list --hold)
            ;;
        *)
            packages=$(pacman -Slq)
            ;;
    esac
    COMPREPLY=($(compgen -W "$packages" -- "$cur"))
}
_apt() {
    local cur prev words cword
    _init_completion || return
    if [ "$cword" = 1 ]; then
        COMPREPLY=($(compgen -W '-c -l -s -u autoclean autopurge autoremove clean depends download full-upgrade help install list mark rdepends reinstall remove search show update' -- "$cur"))
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
                    COMPREPLY=($(compgen -W '--auto-installed --hold --installed --manual-installed --removable --upgradable' -- "$cur"))
                fi
                ;;
            install | reinstall)
                if [ "$cword" = 2 ]; then
                    if [ -z "$cur" ] || [[ "$cur" == --* ]]; then
                        COMPREPLY=($(compgen -W '--mark-auto' -- "$cur"))
                        return
                    fi
                fi
                if [[ "$cur" == [./$]* ]]; then
                    _filedir
                else
                    _apt_complete_packages
                fi
                ;;
            remove | autoremove | autopurge)
                if [ "$cword" = 2 ]; then
                    if [ -z "$cur" ] || [[ "$cur" == --* ]]; then
                        COMPREPLY=($(compgen -W '--save-configurations' -- "$cur"))
                        return
                    fi
                fi
                _apt_complete_packages 'local'
                ;;
            depends | rdepends)
                if [ "$cword" = 2 ]; then
                    if [ -z "$cur" ] || [[ "$cur" == --* ]]; then
                        COMPREPLY=($(compgen -W '--recurse' -- "$cur"))
                        return
                    fi
                fi
                _apt_complete_packages
                ;;
            mark)
                if [ "$cword" = 2 ]; then
                    COMPREPLY=($(compgen -W '--auto --hold --manual --unhold' -- "$cur"))
                elif [ "${words[2]}" = '--unhold' ]; then
                    _apt_complete_packages 'hold'
                else
                    _apt_complete_packages 'local'
                fi
                ;;
            \-l)
                _apt_complete_packages 'local'
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

if [ $# -gt 0 ]; then
    main "$@"
else
    apt_help
fi
