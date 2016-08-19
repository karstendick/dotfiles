# Joshua's dot-files

This repository contains all of my configuration files (most notably those for
Vim). You may notice that none of the files are actually "dot" files in that
they do not start with a '.'. This is to make them non-hidden files.

Forked from Buck's dotfiles: https://github.com/b-ryan/dotfiles

Thanks also to: https://github.com/mathiasbynens/dotfiles and https://github.com/timvisher

## Installation

Just run

```bash
./install.sh [install-type] # install-type can be 'default', 'work', or 'necromancer'
```

It will create symlinks for all the dot-files in your home directory. It will
overwrte files wherever it tries to install stuff, but will back everything
up into the .bk directory.

## XMonad with Gnome

My XMonad configs are designed to work with GNOME. You only need one
requirement for it to work:

    sudo apt-get install gnome-panel

Then log out and log back in using the XMonad with GNOME session.
