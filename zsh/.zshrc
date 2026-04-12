HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt autocd
bindkey -e

# terminfo
# Key bindings using terminfo for portability
typeset -g -A key

key[Home]="${terminfo[khome]}"
key[End]="${terminfo[kend]}"
key[Insert]="${terminfo[kich1]}"
key[Backspace]="${terminfo[kbs]}"
key[Delete]="${terminfo[kdch1]}"
key[Up]="${terminfo[kcuu1]}"
key[Down]="${terminfo[kcud1]}"
key[Left]="${terminfo[kcub1]}"
key[Right]="${terminfo[kcuf1]}"
key[PageUp]="${terminfo[kpp]}"
key[PageDown]="${terminfo[knp]}"
key[Shift-Tab]="${terminfo[kcbt]}"
key[Control-Left]="${terminfo[kLFT5]}"
key[Control-Right]="${terminfo[kRIT5]}"

# Bind keys if defined
[[ -n "${key[Home]}"      ]] && bindkey -- "${key[Home]}"       beginning-of-line
[[ -n "${key[End]}"       ]] && bindkey -- "${key[End]}"        end-of-line
[[ -n "${key[Insert]}"    ]] && bindkey -- "${key[Insert]}"     overwrite-mode
[[ -n "${key[Backspace]}" ]] && bindkey -- "${key[Backspace]}"  backward-delete-char
[[ -n "${key[Delete]}"    ]] && bindkey -- "${key[Delete]}"     delete-char
[[ -n "${key[Up]}"        ]] && bindkey -- "${key[Up]}"         history-beginning-search-backward
[[ -n "${key[Down]}"      ]] && bindkey -- "${key[Down]}"       history-beginning-search-forward
[[ -n "${key[Left]}"      ]] && bindkey -- "${key[Left]}"       backward-char
[[ -n "${key[Right]}"     ]] && bindkey -- "${key[Right]}"      forward-char
[[ -n "${key[PageUp]}"    ]] && bindkey -- "${key[PageUp]}"     beginning-of-buffer-or-history
[[ -n "${key[PageDown]}"  ]] && bindkey -- "${key[PageDown]}"   end-of-buffer-or-history
[[ -n "${key[Shift-Tab]}" ]] && bindkey -- "${key[Shift-Tab]}"  reverse-menu-complete
[[ -n "${key[Control-Left]}"  ]] && bindkey -- "${key[Control-Left]}"  backward-word
[[ -n "${key[Control-Right]}" ]] && bindkey -- "${key[Control-Right]}" forward-word
WORDCHARS=''

# Ensure terminal application mode for valid terminfo
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
    autoload -Uz add-zle-hook-widget
    function zle_application_mode_start { echoti smkx }
    function zle_application_mode_stop { echoti rmkx }
    add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
    add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
fi



# Completions
zstyle ':completion:*' completer _complete _ignored _correct
zstyle ':completion:*' matcher-list '' 'm:{[:lower:]}={[:upper:]}' 'r:|[._-]=** r:|=**'
zstyle :compinstall filename '/home/yanis/.zshrc'
zstyle ':completion:*' menu select 

autoload -Uz compinit
compinit

bindkey "^ " autosuggest-accept

# Edit with nvim
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M emacs '^O' edit-command-line


# Functions

mkcd ()
{
    mkdir -p -- "$1" && cd -P -- "$1"
}

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

gg()
{
    target = git branch | fzf | str trim
    git switch $target
}


findandreplace()
{
    rg --hidden $search --no-ignore --files-with-matches | xargs sed -i "s/($1)/($2)/g"
}

y()
{
    tmp=$(mktemp -t "yazi-cwd.XXXXXX")
    echo "tmp file is $tmp" >> /tmp/ylogfile
    yazi ...$@ --cwd-file $tmp
    cwd=$(cat $tmp)
    if [[ -n $cwd && "$cwd" != "$PWD" ]]; then
        cd $cwd
    fi
    rm -f $tmp
}

# Environment

export EDITOR=nvim
export VISUAL=nvim
export SUDO_EDITOR="nvim --noplugin"
path=($HOME/bin/ $path)

secrets_dir="${HOME}/.config/secrets"
if [ -d "${secrets_dir}" ]; then
    for file in "${secrets_dir}"/*; do
        [ -f "${file}" ] && . "${file}"
    done
fi

# alias
alias ls="eza"
export EXA_COLORS="da=0" # set the date field white

alias zz.st="curl -F 'file=@-' 0x0.st"

alias gl="git log --oneline --graph --decorate"
alias gla="git log --oneline --graph --decorate --all"
alias gs="git status"
alias fastclone="git clone --depth=1 --recurse-submodules --shallow-submodules "
alias unpushed='git log --branches --not --remotes --no-walk --decorate --oneline'

alias la="ls -a"
alias ll="ls -l --time-style=long-iso"
alias l="ll"
alias lla="ls -la --time-style=long-iso"
alias lt="exa -abghl --time-style=long-iso --tree"
alias lll="exa -abghHliS --time-style=long-iso"
alias ta="tmux a"
alias dc="docker compose"
alias dca="docker compose --profile '*'"

alias vi="nvim"
alias ld="lazydocker"

alias fuck="killall -9"

# Only enable Kitty's ssh kitten when we're actually running inside Kitty
# (This works great even inside tmux sessions started from Kitty)
if [[ -n "$KITTY_WINDOW_ID" ]]; then
    alias ssh="kitty +kitten ssh"
fi

# ~/.zshrc or ~/.bashrc

source '/usr/share/zsh-antidote/antidote.zsh'
antidote load ${ZDOTDIR:-$HOME}/.zsh_plugins.txt
eval "$(starship init zsh)"


