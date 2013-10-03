local ZT_BASE_PATH="${zshore_dir}/.tmux_base"

# : Helper functions
function tmux_get_session_id ()			{ echo "$(tmux list-panes -F '#{session_id}' -t "${TMUX_PANE}" | head -n 1)" }
function tmux_get_window_id ()			{ echo "$(tmux list-panes -F '#{window_id}' -t "${TMUX_PANE}" | head -n 1)" }
function tmux_get_pane_id ()			{ echo "${TMUX_PANE}" }
function tmux_get_session_name ()		{ echo "$(tmux list-panes -F '#{session_name}' -t "${TMUX_PANE}" | head -n 1)" }
function tmux_get_window_name ()		{ echo "$(tmux list-panes -F '#{window_name}' -t "${TMUX_PANE}" | head -n 1)" }
function tmux_check_window_hardnamed ()	{ tmux show-window-options | grep --quiet "automatic-rename\soff" }

# : Locking
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

# : Restoring
function tmux_restore_session () {
	echo "Going for restore. This should be locked for single entry"

	tmux_lock_dir "${ZT_SESSION_ID}.restore_lock"
	if [[ -f "${ZT_BASE_PATH}/${ZT_SESSION_ID}.log" ]]; then
		
	fi
	tmux_unlock_dir "${ZT_SESSION_ID}.restore_lock"
	# set ZSH_TMUX_MODE so that panes know they are in restore mode
	#...
	# Restore dirstack
#	if [[ -f "${DIRSFILE}" ]]; then
#		dirstack=( ${(f)"$(< "$DIRSFILE")"} )
#		local last_dir="${dirstack[${#dirstack}]}"
#		[[ -d "${last_dir}" ]] && cd "${last_dir}"
#	fi
	#...
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
	echo "DEBUG: new: ${ZSH_TMUX_PATH} vs old: ${ZSH_TMUX_PATH_OLD}"
	# Create the proper directory hierarchy if it does not already exist.
	if [[ "${ZSH_TMUX_PATH}" != "${ZSH_TMUX_PATH_OLD}" ]]; then
		mkdir --parents "${ZT_BASE_PATH}/${ZSH_TMUX_PATH}" 2>/dev/null
	fi
	#If the name of the link to the session is not current, recreate it.
	if [[ "$(readlink "${ZT_BASE_PATH}/${ZT_SESSION_NAME}")" != "${ZT_SESSION_ID}" ]]; then
		echo "DEBUG: session symlink renamed"
		tmux_lock_dir "${ZT_SESSION_ID}.session_lock"
		find "${ZT_BASE_PATH}" -lname "${(q)ZT_SESSION_ID}" -exec rm -f {} \+
		ln --symbolic "${ZT_SESSION_ID}" "${ZT_BASE_PATH}/${ZT_SESSION_NAME}"
		tmux_unlock_dir "${ZT_SESSION_ID}.session_lock"
	fi
	# If the window is hardnamed, create the appropriate symlink.
	if tmux_check_window_hardnamed && [[ "$(readlink "${ZT_BASE_PATH}/${ZT_SESSION_ID}/${ZT_WINDOW_NAME}")" != "${ZT_WINDOW_ID}" ]]; then
		echo "DEBUG: window symlink renamed"
		tmux_lock_dir "${ZT_SESSION_ID}/${ZT_WINDOW_ID}.window_lock"
		find "${ZT_BASE_PATH}/${ZT_SESSION_ID}" -lname "${ZT_WINDOW_ID}" -exec rm -f {} \+
		ln --symbolic "${ZT_WINDOW_ID}" "${ZT_BASE_PATH}/${ZT_SESSION_ID}/${ZT_WINDOW_NAME}"
		tmux_unlock_dir "${ZT_SESSION_ID}/${ZT_WINDOW_ID}.window_lock"
	fi
	# If the pane was previously being tracked, and it has changed tracking path, move its stuff to the new location and cleanup the old.
	if [[ -n "${ZSH_TMUX_PATH_OLD}" ]] && [[ "${ZSH_TMUX_PATH}" != "${ZSH_TMUX_PATH_OLD}" ]]; then
		echo "DEBUG: session/window/pane_path renamed"
		mv "${ZT_BASE_PATH}/${ZSH_TMUX_PATH_OLD}/"{histfile,dirsfile}(N) "${ZT_BASE_PATH}/${ZSH_TMUX_PATH}/"

		local ZT_SESSION_ID_OLD="${ZSH_TMUX_PATH_OLD%%/*/*}"
		local ZT_WINPANE_OLD="${ZSH_TMUX_PATH_OLD#*/}"
		local ZT_WINDOW_ID_OLD="${ZT_WINPANE_OLD%%/*}"
		
		# Recursively delete pane, window and session directories if they are empty.
		if (pushd -q "${ZT_BASE_PATH}/${ZT_SESSION_ID_OLD}"; rmdir --parents "${ZT_WINPANE_OLD}"); then
			find "${ZT_BASE_PATH}/${ZT_SESSION_ID_OLD}" -lname "${ZT_WINDOW_ID_OLD}" -exec rm {} \+
			if (pushd -q "${ZT_BASE_PATH}"; rmdir --parents "${ZT_SESSION_ID_OLD}"); then
				find "${ZT_BASE_PATH}" -lname "${ZT_SESSION_ID_OLD}" -exec rm {} \+
			fi
		fi
		HISTFILE="${ZT_BASE_PATH}/${ZSH_TMUX_PATH}/histfile"
		DIRSFILE="${ZT_BASE_PATH}/${ZSH_TMUX_PATH}/dirsfile"
	# Else (initial entry), create the history and dirstack file.
	elif [[ -z "${ZSH_TMUX_PATH_OLD}" ]]; then
		echo "DEBUG: _normally_ initial tracking"
		HISTFILE="${ZT_BASE_PATH}/${ZSH_TMUX_PATH}/histfile"
		DIRSFILE="${ZT_BASE_PATH}/${ZSH_TMUX_PATH}/dirsfile"
		print -lD ${PWD} ${(u)dirstack} > "${DIRSFILE}"
		#if [[ ${chpwd_functions[(r)tmux_chpwd_dump_hook]} != tmux_chpwd_dump_hook ]]; then
		#	chpwd_functions+=(tmux_chpwd_dump_hook)
		#fi
		add-zsh-hook chpwd tmux_chpwd_dump_hook
		#if [[ ${zshexit_functions[(r)tmux_zshexit_hook]} != tmux_zshexit_hook ]]; then
		#	zshexit_functions+=(tmux_zshexit_hook)
		#fi
		add-zsh-hook zshexit tmux_zshexit_hook
	fi
	echo "DEBUG: reschedule"
	sched +00:01:00 tmux_track_pane
}

# : Hooks
function tmux_chpwd_dump_hook () {
	if [[ "${PWD}" != "${OLDPWD}" ]]; then
		print -lD ${PWD} >> "${DIRSFILE}"
	fi
}
function tmux_zshexit_hook () {
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

functions -T tmux_schedule_named_session_check_callback tmux_track_pane tmux_chpwd_dump_hook tmux_lock_dir tmux_unlock_dir tmux_chpwd_dump_hook tmux_zshexit_hook tmux_restore_session

# : Main
typeset +gx ZSH_TMUX_INSIDE ZSH_TMUX_PATH
function {
	# Inside tmux:
	if [[ "$ZSH_TMUX_INSIDE" = "true" ]]; then
		local ZT_SESSION_NAME="$(tmux_get_session_name)"
		# Numerical session:
		if [[ "${ZT_SESSION_NAME}" =~ "^[[:digit:]]*$" ]]; then
			tmux_schedule_named_session_check_callback
		# Named session:
		else
			# Session has snapshot:
			if [[ -h "$(find "${ZT_BASE_PATH}" -xtype d -name "${ZT_SESSION_NAME}")" ]]; then
				case "$ZSH_TMUX_MODE" in
					restore)
						tmux_track_pane
						unset ZSH_TMUX_MODE
						;;
					*)
						tmux_restore_session
						;;
				esac
			# Session has no snapshot:
			else
				tmux_track_pane
			fi
		fi
	# Outside tmux:
	else
		add-zsh-hook -d chpwd tmux_chpwd_dump_hook
		add-zsh-hook -d zshexit tmux_zshexit_hook
	fi
}
#TODO: Remove all environment garbage here.
unfunction tmux_track_pane

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
