if [ "$TMUX" = "" ]; then tmux new -s root; fi

export ZSH="/home/yanis/.oh-my-zsh"

ZSH_THEME="robbyrussell"


# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
	git
	zsh-autosuggestions
	rust
)

source $ZSH/oh-my-zsh.sh

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#44bbbb"

NVIM_CONFIG_DIR="~/.dotfiles/nvim/.config/nvim/"

bindkey "^ " autosuggest-accept
bindkey "^[[A" history-beginning-search-backward
bindkey "^[[B" history-beginning-search-forward

# TERM=xterm-256color


# functions
mkcd ()
{
	mkdir -p -- "$1" && cd -P -- "$1"
}

# Repeat a command every second and print the output cleanly
everysec ()
{
	emulate -LR sh # Inherit environment

	CMD=$@

	CYAN='\033[0;36m'
	NC='\033[0m' # No Color

	while true; do
		output=$($CMD 2>&1)
		clear
		echo -e $CYAN"$(date '+%R:%S') | $CMD"$NC
		echo "$output"
		sleep 1
	done
}


export GOPATH=$HOME/go

PATH=$PATH:$GOPATH/bin
PATH=$PATH:$HOME/.local/scripts
PATH=$PATH:$HOME/.local/bin
PATH=$PATH:$HOME/opt/GNAT/2021/bin/
PATH=$PATH:/snap/bin
export LD_LIBRARY_PATH=/lib:/usr/lib:/usr/local/lib
export PATH=$PATH:/usr/lib/cargo/bin
export EDITOR=nvim

# alias
alias ls="exa"
export EXA_COLORS="da=0" # set the date field white

alias hy='hyprctl dispatch'

# TODO: lazily get the container id from a script, in case it changes at runtime
# alias atlogs="docker logs -f $(docker ps | grep avesterra:latest | awk '{print $1}')"


# quick paths
alias gl="git log --oneline --graph --decorate"
alias gla="git log --oneline --graph --decorate --all"
alias gs="git status"
alias fastclone="git clone --depth=1 --recurse-submodules --shallow-submodules "

alias la="ls -a"
alias ll="ls -l --time-style=long-iso"
alias l="ll"
alias lla="ls -la --time-style=long-iso"
alias lt="exa -abghl --time-style=long-iso --tree"
alias lll="exa -abghHliS --time-style=long-iso"
alias vi="nvim"

alias fuck="killall -9"

# Vim Config
alias vc="vi $NVIM_CONFIG_DIR/init.* --cmd 'cd %:h'"


#bindings


###############################################################################


eval "$(starship init zsh)"

alias luamake=/home/yanis/.cache/nvim/nlua/sumneko_lua/lua-language-server/3rd/luamake/luamake

export AVIAL_REPO_PATH=/home/yanis/ledr/Orchestra-AvesTerra/

autoload -Uz compinit
zstyle ':completion:*' menu select
fpath+=~/.zfunc

