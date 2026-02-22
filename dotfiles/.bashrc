# ~/.bashrc — Pi 5 media server

# Non-interactive? bail
case $- in *i*) ;; *) return;; esac

# --- History ---
HISTCONTROL=ignoreboth:erasedups
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend

# --- Shell opts ---
shopt -s checkwinsize
shopt -s globstar 2>/dev/null
shopt -s cdspell 2>/dev/null

# --- Prompt ---
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# --- Aliases ---
alias ll='ls -lAhF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'

# Docker / compose shortcuts
alias dc='docker compose'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dlogs='docker compose logs -f --tail=50'
alias dre='docker compose restart'
alias dup='docker compose up -d'
alias ddown='docker compose down'
alias dpull='docker compose pull'

# Quick navigation
alias ms='cd /opt/mediaserver'
alias msl='cd /opt/mediaserver && docker compose logs -f --tail=30'

# System
alias dfh='df -h / /dev/nvme0n1p2 2>/dev/null | uniq'
alias memf='free -h'
alias temps='vcgencmd measure_temp 2>/dev/null || echo "vcgencmd not available"'
alias ports='ss -tlnp'

# --- Completion ---
if ! shopt -oq posix; then
  [ -f /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion
fi

# --- PATH ---
[ -d "$HOME/bin" ] && PATH="$HOME/bin:$PATH"
[ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"

# Source local overrides if present
[ -f ~/.bashrc.local ] && . ~/.bashrc.local
