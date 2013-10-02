local ZT_BASE_PATH="${zshore_dir}/.tmux_base"

# : Helper functions
function tmux_get_session_id ()			{ echo "$(tmux list-panes -F '#{session_id}' | head -n 1)" }
function tmux_get_window_id ()			{ echo "$(tmux list-panes -F '#{window_id}' | head -n 1)" }
function tmux_get_pane_id ()			{ echo "${TMUX_PANE}" }
function tmux_get_session_name ()		{ echo "$(tmux list-panes -F '#{session_name}' | head -n 1)" }
function tmux_get_window_name ()		{ echo "$(tmux list-panes -F '#{window_name}' | head -n 1)" }
function tmux_check_window_hardnamed ()	{ tmux show-window-options | grep --quiet "automatic-rename\soff" }

# : Various
function tmux_lock_dir () {
	until mkdir "${ZT_BASE_PATH}/${(Q)1}" 2>/dev/null; do
	done
}
function tmux_unlock_dir () {
	rmdir "${ZT_BASE_PATH}/${(Q)1}" 2>/dev/null
}

# : Callbacks
function tmux_schedule_named_session_check_callback () {
	local ZT_SESSION_NAME="$(tmux_get_session_name)"
	if [[ "${ZT_SESSION_NAME}" =~ "^[[:digit:]]*$" ]]; then
		sched +00:01:00 tmux_schedule_named_session_check_callback
	else
		tmux_track_pane
	fi
}

# : Tracking
function tmux_track_pane () {
	local ZT_SESSION_ID="$(tmux_get_session_id)"
	local ZT_WINDOW_ID="$(tmux_get_window_id)"
	local ZT_PANE_ID="$(tmux_get_pane_id)"
	local ZT_SESSION_NAME="$(tmux_get_session_name)"
	local ZT_WINDOW_NAME="$(tmux_get_window_name)"
	local ZSH_TMUX_PATH_OLD="$ZSH_TMUX_PATH"
	ZSH_TMUX_PATH="${ZT_SESSION_ID}/${ZT_WINDOW_ID}/${ZT_PANE_ID}"
	# Create the proper directory hierarchy if it does not already exist.
	if [[ "${ZSH_TMUX_PATH}" != "${ZSH_TMUX_PATH_OLD}" ]]; then
		mkdir --parents "${ZT_BASE_PATH}/${ZSH_TMUX_PATH}" 2>/dev/null
	fi
	#If the name of the link to the session is not current, recreate it.
	if [[ "$(readlink "${ZT_BASE_PATH}/${ZT_SESSION_NAME}_${ZT_SESSION_ID}")" != "${ZT_SESSION_ID}" ]]; then
		tmux_lock_dir "${ZT_SESSION_ID}.session_lock"
		##rm -f ${(q)ZT_BASE_PATH}/*_${(q)ZT_SESSION_ID}			## This does not work for some reason.
		find "${ZT_BASE_PATH}" -lname "${(q)ZT_SESSION_ID}" -exec rm -f {} \;
		ln --symbolic "${ZT_SESSION_ID}" "${ZT_BASE_PATH}/${ZT_SESSION_NAME}_${ZT_SESSION_ID}"
		tmux_unlock_dir "${ZT_SESSION_ID}.session_lock"
	fi
	# If the window is hardnamed, create the appropriate symlink.
	if tmux_check_window_hardnamed && [[ "$(readlink "${ZT_BASE_PATH}/${ZT_SESSION_ID}/${ZT_WINDOW_NAME}_${ZT_WINDOW_ID}")" != "${ZT_WINDOW_ID}" ]]; then
		tmux_lock_dir "${ZT_SESSION_ID}/${ZT_WINDOW_ID}.window_lock"
		##rm -f ${(q)ZT_BASE_PATH}/${(q)ZT_SESSION_ID}/*_${ZT_WINDOW_ID}
		find "${ZT_BASE_PATH}/${ZT_SESSION_ID}" -lname "${ZT_WINDOW_ID}" -exec rm -f {} \+
		ln --symbolic "${ZT_WINDOW_ID}" "${ZT_BASE_PATH}/${ZT_SESSION_ID}/${ZT_WINDOW_NAME}_${ZT_WINDOW_ID}"
		tmux_unlock_dir "${ZT_SESSION_ID}/${ZT_WINDOW_ID}.window_lock"
	fi
	# If the pane was previously being tracked, and it has changed tracking path, move its stuff to the new location and cleanup the old.
	if [[ -n "${ZSH_TMUX_PATH_OLD}" ]] && [[ "${ZSH_TMUX_PATH}" != "${ZSH_TMUX_PATH_OLD}" ]]; then
		mv "${ZT_BASE_PATH}/${ZSH_TMUX_PATH_OLD}/"{histfile,dirsfile}(N) "${ZT_BASE_PATH}/${ZSH_TMUX_PATH}/"

		local ZT_SESSION_ID_OLD="${ZSH_TMUX_PATH_OLD%%/*/*}"
		local ZT_WINPANE_OLD="${ZSH_TMUX_PATH_OLD#*/}"
		local ZT_WINDOW_ID_OLD="${ZT_WINPANE_OLD%%/*}"
		
		# Recursively delete pane, window and session directories if they are empty.
		if (pushd -q "${ZT_BASE_PATH}/${ZT_SESSION_ID_OLD}"; rmdir --parents "${ZT_WINPANE_OLD}"); then
			##rm "*_${ZT_WINDOW_ID_OLD}"
			find "${ZT_BASE_PATH}/${ZT_SESSION_OD_OLD}" -lname "${ZT_WINDOW_ID_OLD}" -exec rm {} \+
			if (pushd -q "${ZT_BASE_PATH}"; rmdir --parents "${ZT_SESSION_ID_OLD}"); then
				##rm "*_${ZT_SESSION_ID_OLD}"
				find "${ZT_BASE_PATH}" -lname "${ZT_SESSION_ID_OLD}" -exec rm {} \+
			fi
		fi
		HISTFILE="${ZT_BASE_PATH}/${ZSH_TMUX_PATH}/histfile"
		DIRSFILE="${ZT_BASE_PATH}/${ZSH_TMUX_PATH}/dirsfile"
	# Else, create the history and dirstack file.
	elif [[ -z "${ZSH_TMUX_PATH_OLD}" ]]; then
		HISTFILE="${ZT_BASE_PATH}/${ZSH_TMUX_PATH}/histfile"
		DIRSFILE="${ZT_BASE_PATH}/${ZSH_TMUX_PATH}/dirsfile"
		{ dirs -p | tac } > "${DIRSFILE}"
		#if [[ ${chpwd_functions[(r)tmux_chpwd_dump_hook]} != tmux_chpwd_dump_hook ]]; then
		#	chpwd_functions+=(tmux_chpwd_dump_hook)
		#fi
		add-zsh-hook chpwd tmux_chpwd_dump_hook
		#if [[ ${zshexit_functions[(r)tmux_zshexit_hook]} != tmux_zshexit_hook ]]; then
		#	zshexit_functions+=(tmux_zshexit_hook)
		#fi
		add-zsh-hook zshexit tmux_zshexit_hook
	fi
	sched +00:01:00 tmux_track_pane
}

# : Hooks
function tmux_chpwd_dump_hook () {
	if [[ "${PWD}" != "${OLDPWD}" ]]; then
		echo "chpwd dump hook"
		echo "${PWD}" >> "${DIRSFILE}"
	fi
}
function tmux_zshexit_hook () {
	echo "tmux pane exit"
	local ZT_SESSION_ID="${ZSH_TMUX_PATH%%/*/*}"
	local ZT_WINPANE="${ZSH_TMUX_PATH#*/}"
	local ZT_WINDOW_ID="${ZT_WINPANE%%/*}"

	# Exiting a pane deletes it from tracking.
	rm -f "${ZT_BASE_PATH}/${ZSH_TMUX_PATH}/"{histfile,dirsfile}(N)
	if (pushd -q "${ZT_BASE_PATH}/${ZT_SESSION_ID}"; rmdir --parents "${ZT_WINPANE}"); then
		find "${ZT_BASE_PATH}/${ZT_SESSION_ID}" -lname "${ZT_WINDOW_ID}" -exec rm {} \+
		if (pushd -q "${ZT_BASE_PATH}"; rmdir --parents "${ZT_SESSION_ID}"); then
			find "${ZT_BASE_PATH}" -lname "${ZT_SESSION_ID}" -exec rm {} \+
		fi
	fi
}

functions -T tmux_schedule_named_session_check_callback tmux_track_pane tmux_chpwd_dump_hook tmux_lock_dir tmux_unlock_dir tmux_chpwd_dump_hook tmux_zshexit_hook

# : Main
function {
	if [[ "$ZSH_TMUX_INSIDE" = "true" ]]; then
		typeset +gx ZSH_TMUX_INSIDE

		local ZT_SESSION_NAME="$(tmux_get_session_name)"
		if [[ "${ZT_SESSION_NAME}" =~ "^[[:digit:]]*$" ]]; then
			tmux_schedule_named_session_check_callback
		else
			case "$ZSH_TMUX_MODE" in
				restore)
					
					;;
				*)
					tmux_track_pane
					;;
			esac
		fi
	fi
}

# Restore session:
	# Issue tmux commands to restore windows and panes in the session, after properly setting tmux_restore mode.
# Track pane:
	# Initial tracking actions (session/window/pane directory hierarchy, symlinking {session,window}name->ids).
	# Change history file.
	# Dump dirstack contents to file.
	# Insert chpwd hook.
	# Insert sanity hook (to check for pane tracking, because panes can change sessions and windows...).
# Main:
	# If we are running under tmux _and_ we pane is not in tmux_restore mode
		# If the pane's session is numeric install schedule hook to check again.
		# If the pane's session is named, and we have a snapshot folder, restore it.
		# If the pane's session is named and we don't have a snapshot, track it.
	# Else if we are running under tmux _and_ pane is in restore mode
		# Track it, and unset tmux_restore mode.
