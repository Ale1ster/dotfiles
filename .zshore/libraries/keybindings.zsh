# Keybindings for vicmd and viins

# vi-mode
bindkey -v

# Load completion lists
zmodload -i zsh/complist

# Load terminfo module, so that terminfo db is available (for keybindings and application mode)
zmodload -i zsh/terminfo

# Load add-zsh-hook
autoload -Uz add-zsh-hook

# Change cursor color (in supporting terminals) to indicate mode (viins vs vicmd)
# Switch the cursor to indicate current mode. Takes as sole argument the keymap we are switching to.
function cursor_indicator_switch () {	
	if [[ "$1" = "vicmd" ]]; then
		case $TERM in
			xterm-256color|screen-256color|rxvt-unicode-256color)
				echo -ne "\033]12;red\007"
				;;
			linux)
				tput cvvis
				;;
		esac
	else
		case $TERM in
			xterm-256color|screen-256color|rxvt-unicode-256color)
				echo -ne "\033]12;grey50\007"
				;;
			linux)
				tput cnorm
				;;
		esac
	fi
}

# Change definition of line-{init,finish} depending on whether terminfo is set (manual p.44)
# Also define exit hook conditionally, since it may need to clear application mode
if (( $+terminfo[smkx] && $+terminfo[rmkx] )); then
	function zle-line-init () {
		echoti smkx
		zle -K viins
	}
	function zle-line-finish () {
		zle -K viins
		echoti rmkx
	}
	function zshexit_restore_cursor_mode () {
		echoti rmkx
		cursor_indicator_switch "viins"
	}
else
	function zle-line-init () {
		zle -K viins
	}
	function zle-line-finish () {
		zle -K viins
	}
	function zshexit_restore_cursor_mode () {
		# We need this for when a user exits the shell while in cmd mode. It resets the cursor.
		cursor_indicator_switch "viins"
	}
fi
#if [[ ${zshexit_functions[(r)zshexit_restore_cursor_mode]} != zshexit_restore_cursor_mode ]]; then
#	zshexit_functions+=(zshexit_restore_cursor_mode)
#fi
add-zsh-hook zshexit zshexit_restore_cursor_mode
# Executed upon keymap change
function zle-keymap-select () {	cursor_indicator_switch $KEYMAP	}
zle -N zle-keymap-select
# Executed when editor is called to read a new line of input (this means with PS{2,3} too)
zle -N zle-line-init
# Executed when editor has finished reading a line of input
zle -N zle-line-finish

# Enable command editing in editor
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd ":"					edit-command-line

# Define a keylist of special keys
typeset -gA key_list
key_list=(
	'Escape'	"\e"
	'Backspace'	"$terminfo[kbs]"
	'Delete'	"$terminfo[kdch1]"
	'Insert'	"$terminfo[kich1]"
	'BackTab'	"$terminfo[kcbt]"
	'F1'		"$terminfo[kf1]"
	'F2'		"$terminfo[kf2]"
	'F3'		"$terminfo[kf3]"
	'F4'		"$terminfo[kf4]"
	'F5'		"$terminfo[kf5]"
	'F6'		"$terminfo[kf6]"
	'F7'		"$terminfo[kf7]"
	'F8'		"$terminfo[kf8]"
	'F9'		"$terminfo[kf9]"
	'F10'		"$terminfo[kf10]"
	'F11'		"$terminfo[kf11]"
	'F12'		"$terminfo[kf12]"
	'Home'		"$terminfo[khome]"
	'End'		"$terminfo[kend]"
	'PageUp'	"$terminfo[kpp]"
	'PageDown'	"$terminfo[knp]"
	'Up'		"$terminfo[kcuu1]"
	'Down'		"$terminfo[kcud1]"
	'Left'		"$terminfo[kcub1]"
	'Right'		"$terminfo[kcuf1]"
)

# Set up keybindings for switching between vicmd and viins.
bindkey -M viins "$key_list[Escape]"	vi-cmd-mode
bindkey -M vicmd "$key_list[Escape]"	vi-insert
# Enable history completion by matching up to cursor
bindkey -M viins "$key_list[Up]"		history-beginning-search-backward
bindkey -M viins "$key_list[Down]"		history-beginning-search-forward
bindkey -M vicmd "$key_list[Up]"		history-beginning-search-backward
bindkey -M vicmd "$key_list[Down]"		history-beginning-search-forward
# Search history in vicmd mode, move cursor in viins mode
bindkey -M viins "$key_list[PageUp]"	beginning-of-line
bindkey -M viins "$key_list[PageDown]"	end-of-line
bindkey -M vicmd "$key_list[PageUp]"	history-search-backward
bindkey -M vicmd "$key_list[PageDown]"	history-search-forward
# Move cursor to beginning and end of line
bindkey -M viins "$key_list[Home]"		beginning-of-line
bindkey -M viins "$key_list[End]"		end-of-line
bindkey -M vicmd "$key_list[Home]"		beginning-of-line
bindkey -M vicmd "$key_list[End]"		end-of-line
# Delete character under cursor
bindkey -M viins "$key_list[Delete]"	delete-char
bindkey -M viins "$key_list[Backspace]"	backward-delete-char
bindkey -M vicmd "$key_list[Delete]"	delete-char
bindkey -M vicmd "$key_list[Backspace]"	backward-delete-char
# Insert next character quoted in viins, enter viins mode in vicmd mode
bindkey -M viins "$key_list[Insert]"	quoted-insert
bindkey -M vicmd "$key_list[Insert]"	vi-insert
# Make _expand do expansion instead of the shell (?) - completion works in vicmd
bindkey -M viins "\t"					complete-word
bindkey -M vicmd "\t"					complete-word
# Incremental search
bindkey -M viins "^r"					history-incremental-search-backward
bindkey -M viins "^s"					history-incremental-search-forward
# Menu completion in insert mode
bindkey -M viins "^e"					reverse-menu-complete
bindkey -M viins "^w"					menu-complete
# Commands (vim-style)
#bindkey -M vicmd ":" execute-named-cmd		#I don't like this.
bindkey -M vicmd "a"					vi-add-next
bindkey -M vicmd "A"					vi-add-eol
bindkey -M vicmd "i"					vi-insert
bindkey -M vicmd "I"					vi-insert-bol
bindkey -M vicmd "r"					vi-replace-chars
bindkey -M vicmd "R"					vi-replace
bindkey -M vicmd "p"					vi-put-after
bindkey -M vicmd "P"					vi-put-before
bindkey -M vicmd "s"					vi-substitute
bindkey -M vicmd "~"					vi-swap-case
bindkey -M vicmd "o"					vi-open-line-below
bindkey -M vicmd "O"					vi-open-line-above
bindkey -M vicmd "c"					vi-change
bindkey -M vicmd "d"					vi-delete
bindkey -M vicmd "y"					vi-yank
bindkey -M vicmd "q"					push-input
bindkey -M vicmd " "					magic-space
bindkey -M vicmd "#"					vi-pound-insert
bindkey -M vicmd "\""					quote-line
bindkey -M vicmd "m"					vi-set-mark
bindkey -M vicmd "\'"					vi-goto-mark
bindkey -M vicmd "gg"					beginning-of-line
bindkey -M vicmd "G"					end-of-line
bindkey -M vicmd "^"					vi-beginning-of-line
bindkey -M vicmd "$"					vi-end-of-line
bindkey -M vicmd "b"					vi-backward-word
bindkey -M vicmd "B"					vi-backward-blank-word
bindkey -M vicmd "w"					vi-forward-word
bindkey -M vicmd "W"					vi-forward-blank-word
bindkey -M vicmd "e"					vi-forward-word-end
bindkey -M vicmd "E"					vi-backward-blank-word
bindkey -M vicmd "h"					vi-backward-char
bindkey -M vicmd "l"					vi-forward-char
bindkey -M vicmd "j"					vi-down-line-or-history
bindkey -M vicmd "k"					vi-up-line-or-history
bindkey -M vicmd "f"					vi-find-next-char
bindkey -M vicmd "F"					vi-find-prev-char
bindkey -M vicmd "%"					vi-match-bracket
bindkey -M vicmd "n"					vi-repeat-find
bindkey -M vicmd "N"					vi-rev-repeat-find
bindkey -M vicmd "/"					vi-history-search-backward
bindkey -M vicmd "?"					vi-history-search-forward
bindkey -M vicmd "v"					vi-repeat-search
bindkey -M vicmd "V"					vi-rev-repeat-search
bindkey -M vicmd "u"					undo
bindkey -M vicmd "^r"					redo
bindkey -M vicmd "."					vi-repeat-change
bindkey -M viins "^v"					vi-quoted-insert
bindkey -M vicmd "^v"					vi-quoted-insert
bindkey -M vicmd "^u"					kill-whole-line
bindkey -M vicmd "^y"					yank
# Change case of word
bindkey -M vicmd "cu"					up-case-word

# Edit command to run as sudo
function sudo-command-line () {
	[[ -z "$BUFFER" ]] && return
	if [[ ! "$BUFFER" =~ "(^sudo\s+)|(^su\s+)" ]]; then
		BUFFER="sudo $BUFFER"
		CURSOR=$((CURSOR+5))
	fi
}
zle -N sudo-command-line
bindkey -M vicmd "su"					sudo-command-line

#Search manual pages for the current command
function man-search-command () {
	[[ -z "$BUFFER" ]] && return
	if [[ ! "$BUFFER" =~ "(^man\s+)" ]]; then
		BUFFER="man ${${=BUFFER}[1]}"
		CURSOR=$((CURSOR+4))
	fi
}
zle -N man-search-command
bindkey -M vicmd "??"					man-search-command
bindkey -M vicmd "man"					man-search-command

# Accept current match in current menu selection and continue
bindkey -M menuselect "^o"				accept-and-infer-next-history
bindkey -M menuselect "^d"				reverse-menu-complete
bindkey -M menuselect "^f"				menu-complete
