# if not running interactively, don't do anything
[ -z "$PS1" ] && return
 
# simple history browsing
export HISTCONTROL=erasedups
export HISTSIZE=10000
shopt -s histappend

function setdirectory { cd /c/GitRepositories ; }

setdirectory

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize
   
# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

## aliases
 
# for fast typing
alias gs='git status'
alias sa='stash apply'
alias sc='stash clear'
alias sd='stash drop'
alias sl='stash list'
alias sp='stash pop'
alias ss='stash save'
alias sw='stash show'
alias gd='git diff'
alias dc='diff --cached'
alias dl='difftool'
alias dk='diff --check'
alias dp='diff --patience'
alias ca='commit -a'
alias cm='commit -m'
alias ga='git add'
alias ai='add -i'
alias ap='apply'
alias as='apply --stat'
alias ac='apply --check'
alias lg='log --oneline --graph --decorate'
alias ob='checkout -b'

export PATH=/opt/local/bin:/opt/local/sbin:$PATH

