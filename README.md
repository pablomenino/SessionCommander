<h3 align="center">SessionCommander</h3>
<p align="center">A Session Manger Tool</p>

<p align="center">
<img src="https://img.shields.io/github/release/pablomenino/SessionCommander.svg">
<img src="https://img.shields.io/github/license/pablomenino/SessionCommander.svg">
</p>

This script was tested on Fedora 23 and Ubuntu 14.04, but is supposed to work on all linux distributions.

## Table of contents

* [How to Use](#how-to-use)

## <a name="how-to-use">How to Use

#### Requirements

* Gnome 3
* Perl

#### Usage

You can add to .bashrc:

nano ~/.bashrc

```
export PATH="$HOME/Projects/gitmfwlab/mfwlab/public/sessioncommander/:$PATH"
```

To use BASH Autocomplete for session name, add this to .bashrc:

nano ~/.bashrc

```
_SessionCommander()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts=$(egrep -v '^#|^ConfVersion|^$' .SessionCommander/SessionCommander.config |  awk -F '\t' '{print $1}')

    COMPREPLY=( $(compgen -W "$opts" -- ${cur}) )
    return 0
}
complete -F _SessionCommander SessionCommander
```

TO-O