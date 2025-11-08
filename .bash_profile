# ~/.bash_profile (Git Bash on Windows)
# Place in C:\Users\<userid> directory
# Exit early if not running interactively
[ -z "$PS1" ] && return

# =========================
# History configuration
# =========================
export HISTCONTROL=erasedups
export HISTSIZE=10000
shopt -s histappend
shopt -s checkwinsize

# =========================
# Functions
# =========================
setdirectory() { [ -d /c/gitrepos ] && cd /c/gitrepos; }
printversion() { git --version; }

# Modern stash save with optional message argument
ss() {
  if [ $# -eq 0 ]; then
    git stash push
  else
    git stash push -m "$*"
  fi
}

# Start in repo root (if present) and show Git version once
setdirectory
printversion

# Make 'less' friendlier (if available)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# =========================
# Git aliases
# =========================
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

# Stash and commit helpers
alias sa='git stash apply'
alias sc='git stash clear'
alias sd='git stash drop'
alias sl='git stash list'
alias sp='git stash pop'
alias sw='git stash show'

alias ca='git commit -a'
alias cm='git commit -m'

# =========================
# PATH setup
# =========================
# Only add macports paths if they exist (rare on Windows)
if [ -d /opt/local/bin ] || [ -d /opt/local/sbin ]; then
  export PATH="/opt/local/bin:/opt/local/sbin:$PATH"
fi

# =========================
# Angular CLI autocompletion
# =========================
# Load only if ng exists, suppressing errors
if command -v ng >/dev/null 2>&1; then
  # shellcheck disable=SC1090
  source <(ng completion script 2>/dev/null)
fi
