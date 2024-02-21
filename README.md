# apt.sh
This is a user-friendly shell wrapper for `pacman` in `msys2`, you can use it just as using the real `apt` in a debian system.

# Why not just use pacman
Because `pacman` sucks.

# Usage
```
usage: apt.sh COMMAND [OPTIONS] [arguments]

COMMANDS:
    update [OPTION]               update list of available packages
        --full-upgrade
    show PACKAGES                 show package details
    download PACKAGES             download packages
    search REGEX                  search for packages
    list [OPTION] [REGEX]         list packages
        --auto-installed
        --installed
        --manual-installed
        --removable
        --upgradable
    install [OPTION] PACKAGES     install packages
        --mark-auto
    reinstall [OPTION] PACKAGES   reinstall packages
        --mark-auto
    full-upgrade                  upgrade the system
    remove PACKAGES               remove packages
    autoremove [PACKAGES]         automatically remove all unused packages
    clean                         remove all files from the cache
    autoclean                     remove old packages from the cache
    mark OPTION PACKAGES          mark packages as manually or automatically installed
        --auto
        --manual
    -l PACKAGES                   list files owned by specific packages
    -s FILES                      search for packages that own specific files
    -c                            install the completion file
    -u                            upgrade this tool from github
    help                          show this help message
```
Most commands are similar to the real `apt`'s commands, but:
- `install` and `reinstall` can also accept urls or files as arguments
- `--mark-auto` will mark packages as automatically installed in any cases
- `mark` is similar to `apt-mark`
- `-l` and `-s` are similar to `dpkg -L` and `dpkg -S` respectively

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
