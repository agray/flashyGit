# if not running interactively, don't do anything
[ -z "$PS1" ] && return
 
# simple history browsing
export HISTCONTROL=erasedups
export HISTSIZE=10000
shopt -s histappend

function setdirectory { cd /c/gitrepos ; }

setdirectory

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize
   
# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

## aliases

alias ga='git add'
alias gp='git push'
alias gl='git log'
alias gs='git status'
alias gd='git diff'
alias gm='git commit -m'
alias gma='git commit -am'
alias gb='git branch'
alias gc='git checkout'
alias gra='git remote add'
alias grr='git remote rm'
alias gpu='git pull'
alias gcl='git clone'
alias gt='git tag'
alias sa='stash apply'
alias sc='stash clear'
alias sd='stash drop'
alias sl='stash list'
alias sp='stash pop'
alias ss='stash save'
alias sw='stash show'
alias ca='commit -a'
alias cm='commit -m'

export PATH=/opt/local/bin:/opt/local/sbin:$PATH
