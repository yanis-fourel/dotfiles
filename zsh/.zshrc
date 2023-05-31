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

# Repeast a command every second and print the output cleanly
everysec ()
{
	emulate -LR sh # Inherit environment

	CMD=$@

	while true; do
		output=$($CMD 2>&1)
		clear
		echo "$(date '+%R:%S') | $CMD"
		echo "$output"
		sleep 1
	done
}


PATH=$PATH:$HOME/.local/scripts
export LD_LIBRARY_PATH=/lib:/usr/lib:/usr/local/lib
export PATH=$PATH:/usr/lib/cargo/bin
export EDITOR=nvim

# alias
alias ls="exa"
export EXA_COLORS="da=0" # set the date field white


# quick paths
alias gooa="cd ~/ledr/Orchestra-AvesTerra/"
alias gomh="cd ~/ledr/Cust-MH/Backend_Rust/"

alias gl="git log --oneline --graph --decorate"
alias gla="git log --oneline --graph --decorate --all"
alias gs="git status"
alias fastclone="git clone --depth=1 --recurse-submodules --shallow-submodules "

alias la="ls -a"
alias ll="ls -l --time-style=long-iso"
alias l="ll"
alias lla="ls -la --time-style=long-iso"
alias lll="exa -abghHliS --time-style=long-iso"
alias vi="nvim"

alias fuck="killall -9"

alias gresetsm="git submodule deinit -f . && git submodule update --init --recursive"
alias wtyping="python /home/yanis/perso/WikipediaTypingPractice/wikityping.py --article"

bindkey -s ^f "tmux-sessionizer\n"

# make with multiple jobs and (most of the time) proper output
alias makej="make -j -Otarget --no-print-directory"

# Vim Config
alias vc="vi $NVIM_CONFIG_DIR/init.* --cmd 'cd %:h'"


#bindings

bindkey -s "^n" '. ranger ^M'


###############################################################################


eval "$(starship init zsh)"

alias luamake=/home/yanis/.cache/nvim/nlua/sumneko_lua/lua-language-server/3rd/luamake/luamake

export AVIAL_REPO_PATH=/home/yanis/ledr/Orchestra-AvesTerra/

autoload -Uz compinit
zstyle ':completion:*' menu select
fpath+=~/.zfunc
