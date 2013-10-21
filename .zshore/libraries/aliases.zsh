#:: If we want to disable autocorrection for specific commands (and their arguments), we alias them as such: "alias %='nocorrect %'"

# shell
alias resource='source ~/.zshenv && source $ZDOTDIR/.zshrc'
alias shit="zcompile \"${zshore_dir}/.zshrc\"; rehash"		# for when you just can't find a new program :)
# lolzies
alias wtf='dmesg'
alias rtfm='man'
alias tldr='less'
alias stalk='finger'
alias oops='rm -rf'
# history
alias history='fc -l 1'
alias hist='builtin history'
# jobs
alias jobs='jobs -l'
# ls
alias ls='ls --color=auto'
alias l='ls'
alias la='ls -A'
alias ll='ls -AlFh'
alias sl='ls'
# tree
alias t='tree'
alias ta='tree -aF --noreport'
alias tap='tree -apF --noreport'
# cd
alias p='pushd'
alias o='popd'
alias c='cd'
alias dv='dirs -v'
# rm
alias rd='rmdir'
alias rmd='rm -r'
alias rf='rm -f'
# vim
alias v='vim'
alias vi='vim'
alias vd='vimdiff'
# tmux
alias tmux='tmux -2'
# git
alias g='git'
alias ga='git add'
alias gap='git add -p'
alias gpl='git pull'
alias gps='git push'
alias gcm='git commit -m'
alias gco='git checkout'
alias grst='git reset --hard HEAD'
alias gf='git fetch --all'
alias gm='git merge'
alias gst='git status'
alias gdf='git diff'
alias gt='git tree'
# networking
alias ping='ping -c 4'
alias lynx='lynx -cfg=~/.lynx.cfg'
# astyle
alias beautify_c='astyle --style=java --indent=force-tab=4 --add-brackets --indent-switches --indent-cases'
# various
alias rlwrap='rlwrap -Acr'
# xclipboard (primary and clipboard) (copy, append, paster, clear, keep)
alias pbc='xsel --input'
alias pba='xsel --append'
alias pbp='xsel --output'
alias pbl='xsel --clear'
alias pbk='xsel --keep'
alias cbc='xsel --input --clipboard'
alias cba='xsel --append --clipboard'
alias cbp='xsel --output --clipboard'
alias cbl='xsel --clear --clipboard'
alias cbk='xsel --output --clipboard | xsel --input --clipboard'
# images
alias feh='feh --auto-zoom --fullscreen'
# mplayer
alias vp='mplayer -name MPPlaylist -use-filename-title -loop 0 -fs'	# name is for workspace anchoring
# system
alias _='sudo'
alias oust='sudo pkill -u'
alias die='sudo shutdown -h now'
alias cya='die'
alias bb='die'
alias reboot='sudo reboot'
# packages
alias sup='sudo pacmatic -Syu'
alias info='pacman -Si'
alias linfo='pacman -Qi'

# suffixes
alias -s c=vim
alias -s h=vim
alias -s spp=vim
alias -s html=vim
alias -s xml=vim
