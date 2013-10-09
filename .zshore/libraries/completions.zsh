#:: zstyle <context>=':completion:function:completer:command:argument:tag' <styles>

# Enable completion system
autoload -Uz compinit && compinit -i -d "$zshore_dir/.internals/.zcompdump"

#:: Forced to put this here, since it is needed for menu coloring.
export LS_COLORS="fi=0:di=34:ln=36:or=31:mi=33:ex=32:so=90:pi=35:cd=1;93:bd=1;31:"
# Color variable for colored completion menus
ZLS_COLORS="$LS_COLORS"
zstyle ':completion:*' list-colors "$ZLS_COLORS"

# Enable highlight of terminal sequences
zle_highlight=(default:none isearch:fg=green region:fg=yellow special:none suffix:fg=cyan,bold)

# Enable menu completion when there are more than 2 items
zstyle ':completion:*' menu select=1 _complete _ignored _approximate

# List of completers to use
zstyle ':completion:*::::' completer _expand _complete _ignored _approximate

# Use cache
zstyle ':completion::complete:*' use-cache true
zstyle ':completion::complete:*' cache-path "$zshore_dir/.internals/cache/"

# Case-insensitive completion (rules: case-insensitive, match right side, match on whole word)
#:: This is the culprit for some mishaps (i.e. invalid pattern character `* when doing tab autocompletion on ssh for an ignored user.	::	Seems that ':completion:*' fails; using ':completion:*::::' instead.
zstyle ':completion:*::::' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|[._-]=* r:|*' 'l:|=* r:|=*'

# Do not complete these users
zstyle ':completion:*:*:*:users' ignored-patterns root bin daemon mail ftp http uuidd dbus nobody polkitd avahi git dnsmasq mpd 'x2go*' mysql

# Process completion
zstyle ':completion:*:*:kill:*:processes' list-colors "=(#b) #([0-9]#) ([0-9a-zA-Z_-]#)* =1;34=1=0"
zstyle ':completion:*:*:kill:*' insert-ids menu
#zstyle ':completion:*:*:killall:*:processes' list-colors "=(#b) #([0-9]#) ([0-9a-zA-Z_-]#)* =1;34=1=0"
zstyle ':completion:*:*:*:*:processes' command "ps -w -w -u $(whoami) -o pid,uname,comm"

# Manuals
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true

# Autocompletion for cd
zstyle ':completion:*:cd:*' tag-order 'local-directories' 'directory-stack' 'path-directories' 'named-directories'
zstyle ':completion:*:cd:*:directory-stack' menu yes select
zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'directory-stack' 'users' 'expand'
#cdpath=(.)				# Use this parameter to define the list of directories for the cd command.
zstyle ':completion:*:(cd|ls):*' special-dirs ..

# Ignore already present entries in some commands
zstyle ':completion:*(rm|kill|diff):*' ignore-line true

# Formatting and messages (I don't like it, but it keep for the sake of clarity)
#zstyle ':completion:*' verbose yes
#zstyle ':completion:*' group-name ''
#zstyle ':completion:*:descriptions' format '%B%d%b'
#zstyle ':completion:*:messages' format '%d'
#zstyle ':completion:*:warnings' format 'No matches for: %d'
#zstyle ':completion:*:errors' format '%B%d (errors: %e)%b'

# Populate hostname completion
zstyle -e ':completion::*:hosts' hosts 'reply=(
	${=${${${${(@M)${(f)"$(cat ~/.ssh/config 2>/dev/null)"}:#Host *}#Host }:#*\**}:#*\?*}}
)'
#	${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) 2>/dev/null)"}%%[#| ]*}//,/ }
#	${=${(f)"$(cat /etc/hosts(|)(N) <<(ypcat hosts 2>/dev/null))"}%%\#*}

# Remote tabcompletion (ssh, rsync, scp, ping, host)
zstyle ':completion:*:ssh:*' tag-order 'users hosts:-host hosts:-domain:domain hosts:-ipaddr:ip\ address hosts *'
zstyle ':completion:*:ssh:*' group-order hosts hosts-domain hosts-host users hosts-ipaddr
zstyle ':completion:*:scp:*' tag-order 'hosts:-host hosts:-domain:domain hosts:-ipaddr:ip\ address hosts *'
zstyle ':completion:*:scp:*' group-order users files all-files hosts hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:rsync:*' tag-order 'hosts:-host hosts-domain:domain hosts:-ipaddr:ip\ address hosts *'
zstyle ':completion:*:rsync:*' group-order hosts hosts-domain hosts-host hosts-ipaddr files
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*.*' loopback localhost
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^*.*' '*@*'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^<->.<->.<->.<->' '127.0.0.*'
#zstyle ':completion:*:(ssh|scp|rsync):*:users' ignored-patterns	#Abandoned for the more generic one

# A single match in the _ignored completer will be displayed, but not inserted (possible: show, menu)
zstyle '*' single-ignored show

# Enable completion for pacmatic (essentially as an alias for pacman)
compdef pacmatic='pacman'
