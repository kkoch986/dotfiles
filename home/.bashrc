#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

export EDITOR=nvim
export USE_GKE_GCLOUD_AUTH_PLUGIN=True


source "$HOME/.aliases"

export PATH="$PATH:$HOME/bin:$HOME/.bin"

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.bash.inc" ]; then . "$HOME/google-cloud-sdk/path.bash.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.bash.inc" ]; then . "$HOME/google-cloud-sdk/completion.bash.inc"; fi

eval "$(direnv hook bash)"

# Pull the latest shared Claude Code skills/rules (hdtradeservices/claude)
alias claude-sync='git -C "$HOME/claude" pull'
