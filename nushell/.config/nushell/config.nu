# config.nu
#
# Installed by:
# version = "0.103.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# This file is loaded after env.nu and before login.nu
#
# You can open this file in your default editor using:
# config nu
#
# See `help config nu` for more options
#
# You can remove these comments if you want or leave
# them for future reference.

$env.config.show_banner = false

export def "from .env" []: string -> record {
  lines 
    | split column '#' 
    | get column1 
    | filter {($in | str length) > 0} 
    | parse "{key}={value}"
    | update value {str trim -c '"'}
    | transpose -r -d
}


use std # does that hit statup time?
use ~/.cache/starship/init.nu

if ("TMUX" not-in $env) {
    let $ec = tmux has-session -t=root err> (std null-device) | complete | get exit_code
    if ($ec == 0) {
        tmux a -t root
    } else {
        tmux new -s root
    }
}

# $env.NVIM_CONFIG_DIR="~/.config/nvim/"


export def --env mkcd [path: path] {
	mkdir $path
    cd $path
}

# Uploads given bytes to [THE NULL POINTER](https://0x0.st)
export def thenullptr []: binary -> nothing {
    $in | curl -F 'file=@-' 0x0.st
}

export def gg [] {
    let target = git branch | fzf | str trim
    git switch $target
}

export def ox [path: path] {
    open $path | explore
}

# Starts Yazi and change the current working directory 
# when exiting Yazi with `q`.
# Exit with `Q` instead to not change current working directory
def --env y [...args] {
    let tmp = (mktemp -t "yazi-cwd.XXXXXX")
        yazi ...$args --cwd-file $tmp
        let cwd = (open $tmp)
        if $cwd != "" and $cwd != $env.PWD {
            cd $cwd
        }
    rm -fp $tmp
}

use std/util "path add"

$env.GOPATH = ($env.HOME | path join "go")
path add ($env.GOPATH | path join "bin")
path add ($env.HOME | path join ".local/scripts")
path add ($env.HOME | path join ".local/bin")

alias hy = hyprctl dispatch


alias gl = git log --oneline --graph --decorate
alias gla = git log --oneline --graph --decorate --all
alias gs = git status
alias fastclone = git clone --depth=1 --recurse-submodules --shallow-submodules 
alias unpushed = git log --branches --not --remotes --no-walk --decorate --oneline
alias ld = lazydocker

alias la = ls -a
alias ll = ls -l
alias l = ll
alias lla = ls -la
alias lt = exa -abghl --tree
alias lll = exa -abghHliS
alias vi = nvim

alias fuck = killall -9

alias lk = sudo docker compose --profile lk



# copy/pasted from carapace setup
source ~/.cache/carapace/init.nu

$env.config.hooks.env_change.PWD = (
    $env.config.hooks.env_change | get -i PWD | default [] | append (
        { ||
            if (which direnv | is-empty) {
                return
            }

            direnv export json | from json | default {} | load-env
        }
    )
)
