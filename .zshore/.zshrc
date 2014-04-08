## ==== BASIC CONFIGURATION ====

# ==== ZSH ENV ====
typeset +gx ZSHENV_SOURCED
if [[ "${ZSHENV_SOURCED}" != "${HOME}/.zshore" ]]; then
	source "${HOME}/.zshenv"
fi

# ==== ZSH OPTIONS ====

# Environment variables
zshore_dir="$ZDOTDIR"

# Directory options
zshore_dir_opts=(AUTO_{CD,PUSHD} CHASE_LINKS PUSHD_{IGNORE_DUPS,MINUS,SILENT,TO_HOME})
# Completion options
zshore_compl_opts=(ALWAYS_{TO_END,LAST_PROMPT} AUTO_{LIST,MENU,NAME_DIRS,PARAM_KEYS,PARAM_SLASH,REMOVE_SLASH} COMPLETE_IN_WORD GLOB_COMPLETE HASH_LIST_ALL LIST_{AMBIGUOUS,PACKED,ROWS_FIRST})
# Expansion/globbing options
zshore_expans_opts=(BAD_PATTERN EQUALS EXTENDED_GLOB GLOB GLOB_DOTS MARK_DIRS MULTIBYTE NOMATCH RC_EXPAND_PARAM RE_MATCH_PCRE UNSET)
# History options
zshore_hist_opts=(EXTENDED_HISTORY HIST_{IGNORE_ALL_DUPS,IGNORE_DUPS,REDUCE_BLANKS,SAVE_BY_COPY,SAVE_NO_DUPS,VERIFY} INC_APPEND_HISTORY)
# Initialization options
zshore_init_opts=(NO_GLOBAL_RCS)
# I/O options
zshore_io_opts=(ALIASES CLOBBER CORRECT no_FLOW_CONTROL INTERACTIVE_COMMENTS)
# Job control options
zshore_jc_opts=(AUTO_CONTINUE BG_NICE CHECK_JOBS no_HUP LONG_LIST_JOBS MONITOR)
# Prompt options
zshore_prompt_opts=(PROMPT_{SP,CR,PERCENT,SUBST} TRANSIENT_RPROMPT)
# Script/function options
zshore_fun_opts=(MULTI_FUNC_DEF MULTIOS)

zshore_opts=($zshore_dir_opts $zshore_compl_opts $zshore_expans_opts $zshore_hist_opts $zshore_init_opts $zshore_io_opts $zshore_jc_opts $zshore_prompt_opts $zshore_fun_opts)
setopt $zshore_opts

# Colors
autoload -Uz colors && colors -i

# Ignore _* patterns during completion (typically used as completion function names)
CORRECT_IGNORE="_*"
# Editor for fc builtin
FCEDIT="vim"
# History characters (history expansion start, quick history substitution start, comment start)
histchars="!^#"
# History file and size
HISTSIZE=100000
SAVEHIST=100000
HISTFILE="$zshore_dir/.history/zsh_history"
# Size of possible matches before zsh asks 'do you want to see all possibilities'
LISTMAX=200
# Redirections without command, use NULLCMD (>) and READNULLCMD (<)
NULLCMD="cat"
READNULLCMD="more"

# Treat these characters as part of a word
WORDCHARS='*?_-.[]~=/&;!#$%^(){}<>'
WORDCHARS=${WORDCHARS//[><&;=(){}\[\]-]}

# ==== PROMPT ====

# Default username and hostname
DEFAULT_USER="ale1ster"
DEFAULT_HOST="briareos"

# Format for parse_git_dirty_and_ahead()
GIT_PROMPT_DIRTY="%F{red}*%f"
GIT_PROMPT_AHEAD="%F{yellow}^%f"
# Format for git_prompt_status()
GIT_PROMPT_UNMERGED="%B%F{black}UM%f%b"
GIT_PROMPT_DELETED="%F{red}D%f"
GIT_PROMPT_RENAMED="%F{blue}R%f"
GIT_PROMPT_MODIFIED="%F{yellow}M%f"
GIT_PROMPT_ADDED="%F{cyan}A%f"
GIT_PROMPT_UNTRACKED="%F{green}U%f"

# Show the username and hostname if they are different than the default ones
function user_and_host_name () {
	UN=""
	HN=""
	UHN=""
	if [[ "$USERNAME" != "$DEFAULT_USER" ]]; then
		UN="%F{yellow}%n%f"
	fi
	if [[ "$HOST" != "$DEFAULT_HOST" ]]; then
		HN="%F{cyan}%m%f"
	fi
#	[[ -n "$UN" ]] && [[ -n "$HN" ]] && echo "$UN@$HN:" && return		##	Currently does not output @:
	[[ -n "$UN" ]] && [[ -n "$HN" ]] && echo "$UN $HN " && return
	[[ -z "$UN" ]] && [[ -z "$HN" ]] && return
	echo "$UN$HN "
}

# Git prompt message functions
# Checks if working tree is dirty, and if there are commits ahead from remote
function parse_git_dirty_and_ahead () {
	GIT_DIRTY_AHEAD=""
	if [[ -n $(git status -s --ignore-submodules=dirty 2> /dev/null) ]]; then
		GIT_DIRTY_AHEAD="$GIT_PROMPT_DIRTY"
	fi
	if $(echo "$(git log origin/$(current_branch)..HEAD 2> /dev/null)" | grep '^commit' &> /dev/null); then
		GIT_DIRTY_AHEAD="$GIT_DIRTY_AHEAD$GIT_PROMPT_AHEAD"
	fi
	echo "$GIT_DIRTY_AHEAD"
}
# Get the status of the working tree
function git_prompt_status () {
	INDEX=$(git status --porcelain 2> /dev/null)
	STATUS=""
	if $(echo "$INDEX" | grep '^?? ' &> /dev/null); then
		STATUS="$GIT_PROMPT_UNTRACKED$STATUS"
	fi
	if $(echo "$INDEX" | grep '^A  ' &> /dev/null); then
		STATUS="$GIT_PROMPT_ADDED$STATUS"
	elif $(echo "$INDEX" | grep '^M  ' &> /dev/null); then
		STATUS="$GIT_PROMPT_ADDED$STATUS"
	fi
	if $(echo "$INDEX" | grep '^ M ' &> /dev/null); then
		STATUS="$GIT_PROMPT_MODIFIED$STATUS"
	elif $(echo "$INDEX" | grep '^AM ' &> /dev/null); then
		STATUS="$GIT_PROMPT_MODIFIED$STATUS"
	elif $(echo "$INDEX" | grep '^ T ' &> /dev/null); then
		STATUS="$GIT_PROMPT_MODIFIED$STATUS"
	fi
	if $(echo "$INDEX" | grep '^R  ' &> /dev/null); then
		STATUS="$GIT_PROMPT_RENAMED$STATUS"
	fi
	if $(echo "$INDEX" | grep '^ D ' &> /dev/null); then
		STATUS="$GIT_PROMPT_DELETED$STATUS"
	elif $(echo "$INDEX" | grep '^AD ' &> /dev/null); then
		STATUS="$GIT_PROMPT_DELETED$STATUS"
	fi
	if $(echo "$INDEX" | grep '^UU ' &> /dev/null); then
		STATUS="$GIT_PROMPT_UNMERGED$STATUS"
	fi
	if [[ -n "$STATUS" ]]; then
		STATUS="%f($STATUS%f)"
	fi
	echo "$STATUS"
}
# Right prompt status (indicator of repo type: do the same when using hg,svn,git)
function rprompt_char () {
	git branch >/dev/null 2>/dev/null && echo "%B%F{black}G%f%b " && return
#	hg root >/dev/null 2>/dev/null && echo "%{$fg_bold[blue]%}hg%{$RESET_COL%}:" && return
}
# Current branch name
function current_branch() {
	ref=$(git symbolic-ref HEAD 2> /dev/null) || return
	echo ${ref#refs/heads/}
}

# Prompt variables (PS1: primary prompt, PS2: command-needs-completion prompt, PS3: select loop prompt, PS4: execution trace prompt)
# Default values: PS1: "%m%# ", PS2: "%_> ", PS3: "%# ", PS4: "+%N:%i> "
PROMPT=$'%(?..[%?] )$(user_and_host_name)%F{green}%4~%f %B%F{black}%y%f%b $(parse_git_dirty_and_ahead)%B%(!.%F{red}#.%F{blue}>)%f%b'
PROMPT2="%F{cyan}%_%f> "
PROMPT3="%F{blue}yar choice%f %#"
PROMPT4="+%F{yellow}[%?]%f%F{red}%N%f:%F{green}%i%f_%F{green}(%I)%f> "
# Right prompt variables (printed when the corresponding prompt is)
RPROMPT=$'$(rprompt_char)%F{red}$(current_branch)%f$(git_prompt_status)'
RPROMPT2="<"
# Spelling correction prompt
SPROMPT="zsh: didja mean '%r' (saw '%R')? [nyae] "

# ==== KEYBINDINGS ====

source $zshore_dir/libraries/keybindings.zsh

# ==== COMPLETION ====

#:: For now, all modules are loaded before calling compinit. Take care for that to still apply in case modules are inserted.

source $zshore_dir/libraries/completions.zsh

## ==== ENVIRONMENT ====

export EDITOR="vim"
export PAGER="less -R"
export LESS="-isCM"
export MANPAGER="less"

## ==== ALIASES and FUNCTIONS ====

# ==== ALIASES ====

source $zshore_dir/libraries/aliases.zsh

# ==== FUNCTIONS ====

source $zshore_dir/libraries/functions.zsh

## ==== CONFIGURATIONS ====

source $zshore_dir/libraries/configurations.zsh

## ==== TEMPORARIES ====

source $zshore_dir/libraries/temps.sh

## ==== PLUGINS ====

# Plugins
plugins=(tmux)
for i in $plugins; do
	source $zshore_dir/plugins/$i.zsh
done
