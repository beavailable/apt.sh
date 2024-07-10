# apt.sh
This is a user-friendly shell wrapper for `pacman` in `msys2`, you can use it just as using the real `apt` in a debian system.

# Why not just use pacman
Because `pacman` sucks.

# Usage
```
usage: apt.sh COMMAND [OPTION]... [ARG]...

COMMANDS:
    update                                update list of available packages
    show PACKAGE...                       show package details
    download PACKAGE...                   download packages
    search [OPTION] REGEX                 search for packages
        --names-only
    list [OPTION] [REGEX]                 list packages
        --auto-installed
        --installed
        --manual-installed
        --removable
        --upgradable
        --held
    install [OPTION] PACKAGE...           install packages
        --mark-auto
    reinstall [OPTION] PACKAGE...         reinstall packages
        --mark-auto
    full-upgrade [OPTIONS]                upgrade the system
        --update
        --overwrite
    remove [OPTION] PACKAGE...            remove packages
        --purge
    autoremove [OPTION] [PACKAGE]...      automatically remove all unused packages
        --purge
    autopurge [PACKAGE]...                an alias for "autoremove --purge"
    depends [OPTION] PACKAGE              list packages that a package depends on
        --recurse
    rdepends [OPTION] PACKAGE             list packages that depend on a package
        --recurse
    clean                                 remove all files from the cache
    autoclean                             remove old packages from the cache
    mark OPTION PACKAGE...                mark packages
        --auto
        --manual
        --hold
        --unhold
    -l PACKAGE...                         list files owned by specific packages
    -s FILE...                            search for packages that own specific files
    -c                                    install the completion file
    -u                                    upgrade this tool from github
    help                                  show this help message
```
Most commands are similar to the real `apt`'s commands, but:
- `list` accepts a `regular expression` argument instead of a `glob pattern` argument
- `install` and `reinstall` can also accept urls as arguments
- `--mark-auto` will mark packages as automatically installed in any cases
- `mark` is similar to `apt-mark`
- `-l` and `-s` are similar to `dpkg -L` and `dpkg -S` respectively

**Note**:
- `mark --hold` and `mark --unhold` work just like the `apt-mark` command which doesn't support `glob pattern` arguments.

# Installation
```bash
curl -Lfo /usr/local/bin/apt https://raw.githubusercontent.com/beavailable/apt.sh/main/apt.sh
```

# Uninstallation
```bash
rm -f /usr/local/bin/apt /usr/local/share/bash-completion/completions/apt
```

# Tips
After installing the completion file, in all cases that a package name is needed as an argument, you can simply type `-<tab>` to complete the current `MINGW_PACKAGE_PREFIX` for you.

For example, if you type `apt install -<tab>`, you'll get:
- `apt install mingw-w64-ucrt-x86_64-` in `UCRT64` environment
- `apt install mingw-w64-clang-x86_64-` in `CLANG64` environment
- `apt install -` in `MSYS` environment (no changes)

And because of this, you need to type `--<tab>` to complete options in these cases.
