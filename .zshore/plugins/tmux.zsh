local ZT_BASE_PATH="${zshore_dir}/.tmux_base"
# : Helpers
function _zsh_tmux_get_session_id ()			{ echo "$(tmu\x list-panes -F '#{session_id}' -t "${TMUX_PANE}" | head -n 1)" }
function _zsh_tmux_get_window_id ()				{ echo "$(tmu\x list-panes -F '#{window_id}' -t "${TMUX_PANE}" | head -n 1)" }
function _zsh_tmux_get_pane_id ()				{ echo "${TMUX_PANE}" }
function _zsh_tmux_get_session_name ()			{ echo "$(tmu\x list-panes -F '#{session_name}' -t "${TMUX_PANE}" | head -n 1)" }
function _zsh_tmux_get_window_name ()			{ echo "$(tmu\x list-panes -F '#{window_name}' -t "${TMUX_PANE}" | head -n 1)" }
function _zsh_tmux_check_window_hardnamed ()	{ tmu\x show-window-options | \grep --quiet "automatic-rename\soff" }
function _zsh_tmux_get_last_create_time ()		{ echo "$(tmu\x list-clients -F '#{client_created}' -t ${(Q)1})" }
function _zsh_tmux_get_last_restore_time ()		{ \sed -n "/session restored/h; \${x;s/:session restored//;p}" "${ZT_BASE_PATH}/${(Q)1}.log" }
# : Locking
function _zsh_tmux_lock_dir ()		{ until mkdir "${ZT_BASE_PATH}/${(Q)1}" 2>/dev/null; do; done }
function _zsh_tmux_unlock_dir ()	{ rmdir "${ZT_BASE_PATH}/${(Q)1}" 2>/dev/null }
# : Logging
function _zsh_tmux_log_restore_time ()	{ echo "$(\date "+%s"):session restored" >> "${1}" }
function _zsh_tmux_log_dummy_time ()	{ echo "$(tmu\x list-clients -F '#{client_created}' -t "${(Q)2}"):session restored" >> "${1}" }
function _zsh_tmux_check_restore ()		{
	# If there is a symlink to the session folder:
	if [[ -h "$(\find "${ZT_BASE_PATH}" -xtype d -name "${(Q)1}")" ]]; then
		# and the logfile does not exist _or_ the last restore time is before the session create time:
		if [[ "$(_zsh_tmux_get_last_create_time "${(q)1}")" -gt "$(_zsh_tmux_get_last_restore_time "${(q)1}")" ]]; then
			echo "restore criteria met"
			return 0
		fi
	fi
	return 1
}
# : Callbacks
function _zsh_tmux_sched_callback ()	{
	local ZT_SESSION_NAME="$(_zsh_tmux_get_session_name)"
	# Numerical session:
	if [[ "${ZT_SESSION_NAME}" =~ "^[[:digit:]]*$" ]]; then
		sched +00:01:00 _zsh_tmux_sched_callback
	# Named session:
	else
		# Session needs restore:
		if _zsh_tmux_check_restore "${ZT_SESSION_NAME}"; then
			case "${ZSH_TMUX_MODE}" in
				# Single panes under restore mode come here:
				restore)
					_zsh_tmux_track_pane
					#unset ZSH_TMUX_MODE
					;;
				# One pane executes restore successfully:
				*)
					_zsh_tmux_restore_session
					;;
			esac
		# Session is tracked:
		else
			_zsh_tmux_track_pane
		fi
		unset ZSH_TMUX_MODE
	fi
}
# : Hooks
function _zsh_tmux_chpwd_hook ()	{
	if [[ "${PWD}" != "${OLDPWD}" ]]; then
		print -lD "${PWD}" >> "${DIRSFILE}"
	fi
}
function _zsh_tmux_zshexit_hook ()	{
	local ZT_SESSION_ID="${ZSH_TMUX_PATH%%/*/*}"
	local ZT_WINPANE="${ZSH_TMUX_PATH#*/}"
	local ZT_WINDOW_ID="${ZT_WINPANE%%/*}"
	# Exiting a pane deletes it from tracking.
	rm --force "${ZT_BASE_PATH}/${ZSH_TMUX_PATH}/"{histfile,dirsfile}(N)
	if (pushd -q "${ZT_BASE_PATH}/${ZT_SESSION_ID}"; rmdir --parents "${ZT_WINPANE}"); then
		\find "${ZT_BASE_PATH}/${ZT_SESSION_ID}" -lname "${ZT_WINDOW_ID}" -execdir rm --force '{}' '+'
		if (pushd -q "${ZT_BASE_PATH}"; rmdir --parents "${ZT_SESSION_ID}"); then
			local ZT_SESSION_NAME="$(\find "${ZT_BASE_PATH}" -lname "${ZT_SESSION_ID}" -exec basename '{}' ';')"
			if [[ -n "${ZT_SESSION_NAME}" ]]; then
				rm --force "${ZT_BASE_PATH}/${(q)ZT_SESSION_NAME}"{,.log}
			fi
		fi
	fi
}
# : Restoring - Tracking
function _zsh_tmux_track_pane ()		{
	local ZT_SESSION_ID="$(_zsh_tmux_get_session_id)"
	local ZT_WINDOW_ID="$(_zsh_tmux_get_window_id)"
	local ZT_PANE_ID="$(_zsh_tmux_get_pane_id)"
	local ZT_SESSION_NAME="$(_zsh_tmux_get_session_name)"
	local ZT_WINDOW_NAME="$(_zsh_tmux_get_window_name)"
	local ZT_TMUX_PATH_OLD="${ZSH_TMUX_PATH}"
	# Save the previous pane path (to check later) and create a new one.
	ZSH_TMUX_PATH="${ZT_SESSION_ID}/${ZT_WINDOW_ID}/${ZT_PANE_ID}"
	echo "DEBUG: new: ${ZSH_TMUX_PATH} vs old: ${ZSH_TMUX_PATH_OLD}"
	# Create the proper directory hierarchy if it does not already exist.
	if [[ "${ZSH_TMUX_PATH}" != "${ZSH_TMUX_PATH_OLD}" ]]; then
		mkdir --parents "${ZT_BASE_PATH}/${ZSH_TMUX_PATH}" 2>/dev/null
	fi
	# If the name of the session symlink is not current, recreate it.
	if [[ "$(readlin\k "${ZT_BASE_PATH}/${ZT_SESSION_NAME}")" != "${ZT_SESSION_ID}" ]]; then
		echo "DEBUG: session symlink renamed"
		_zsh_tmux_lock_dir "${ZT_SESSION_ID}.session_lock"
		#\find "${ZT_BASE_PATH}" -lname "${(q)ZT_SESSION_ID}" -execdir rm --force '{}' '+'
		local ZT_SESSION_NAME_OLD="$(\find "${ZT_BASE_PATH}" -lname "${(q)ZT_SESSION_ID}" -exec basename '{}' ';')"
		if [[ -n "${ZT_SESSION_NAME_OLD}" ]]; then
			rm --force "${ZT_BASE_PATH}/${ZT_SESSION_NAME_OLD}"
			mv "${ZT_BASE_PATH}/"{${(q)ZT_SESSION_NAME_OLD}.log,${(q)ZT_SESSION_NAME}.log} 2>/dev/null
		fi
		\ln --symbolic "${ZT_SESSION_ID}" "${ZT_BASE_PATH}/${ZT_SESSION_NAME}"
		_zsh_tmux_unlock_dir "${ZT_SESSION_ID}.session_lock"
	fi
	# Insert a dummy time to the session log, so that later panes will not try to restore (only in case of tracking without a restore).
	if [[ -f "${ZT_BASE_PATH}/${(q)ZT_SESSION_NAME}.log" ]] || [[ "$(_zsh_tmux_get_last_create_time "${(q)ZT_SESSION_NAME}")" -gt "$(_zsh_tmux_get_last_restore_time "${(q)ZT_SESSION_NAME}")" ]]; then
		echo "DEBUG: debug restore criteria met"
		_zsh_tmux_lock_dir "${ZT_SESSION_ID}.session_lock"
		_zsh_tmux_log_dummy_time "${ZT_BASE_PATH}/${ZT_SESSION_NAME}.log" "${ZT_SESSION_NAME}"
		_zsh_tmux_unlock_dir "${ZT_SESSION_ID}.session_lock"
	fi
	# If the window is hardnamed, create the appropriate symlink.
	if _zsh_tmux_check_window_hardnamed && [[ "$(readlin\k "${ZT_BASE_PATH}/${ZT_SESSION_ID}/${ZT_WINDOW_NAME}")" != "${ZT_WINDOW_ID}" ]]; then
		echo "DEBUG: window symlink renamed"
		_zsh_tmux_lock_dir "${ZT_SESSION_ID}/${ZT_WINDOW_ID}.window_lock"
		\find "${ZT_BASE_PATH}/${ZT_SESSION_ID}" -lname "${ZT_WINDOW_ID}" -execdir rm --force '{}' '+'
		\ln --symbolic "${ZT_WINDOW_ID}" "${ZT_BASE_PATH}/${ZT_SESSION_ID}/${ZT_WINDOW_NAME}"
		_zsh_tmux_unlock_dir "${ZT_SESSION_ID}/${ZT_WINDOW_ID}.window_lock"
	fi
	# If the pane was previously being tracked and it has changed tracking path, move its stuff to the new location and clean up the old.
	if [[ -n "${ZSH_TMUX_PATH_OLD}" ]] && [[ "${ZSH_TMUX_PATH}" != "${ZSH_TMUX_PATH_OLD}" ]]; then
		echo "DEBUG: session/window/pane_path renamed"
		mv "${ZT_BASE_PATH}/${ZSH_TMUX_PATH_OLD}"{histfile,dirsfile}(N) "${ZT_BASE_PATH}/${ZSH_TMUX_PATH}"
		local ZT_SESSION_ID_OLD="${ZSH_TMUX_PATH_OLD%%/*/*}"
		local ZT_WINPANE_OLD="${ZSH_TMUX_PATH_OLD#*/}"
		local ZT_WINDOW_ID_OLD="${ZT_WINPANE_OLD%%/*}"
		# Recursively delete pane, window and session directories (if they are empty).
		if (pushd -q "${ZT_BASE_PATH}/${ZT_SESSION_ID_OLD}"; rmdir --parents "${ZT_WINPANE_OLD}"); then
			\find "${ZT_BASE_PATH}/${ZT_SESSION_ID_OLD}" -lname "${ZT_WINDOW_ID_OLD}" -execdir rm --force '{}' '+'
			if (pushd -q "${ZT_BASE_PATH}"; rmdir --parents "${ZT_SESSION_ID_OLD}"); then
				local ZT_SESSION_NAME_OLD="$(\find "${ZT_BASE_PATH}" -lname "${ZT_SESSION_ID_OLD}" -exec basename '{}' ';')"
				if [[ -n "${ZT_SESSION_NAME_OLD}" ]]; then
					rm --force "${ZT_BASE_PATH}/${ZT_SESSION_NAME_OLD}"
					mv "${ZT_BASE_PATH}/"{${(q)ZT_SESSION_NAME_OLD}.log,${(q)ZT_SESSION_NAME}.log} 2>/dev/null
				fi
			fi
		fi
		HISTFILE="${ZT_BASE_PATH}/${ZSH_TMUX_PATH}/histfile"
		DIRSFILE="${ZT_BASE_PATH}/${ZSH_TMUX_PATH}/dirsfile"
		# Restore dirstack. This should happen only once when we restore a pane. That's why we check for ZSH_TMUX_MODE.
		if [[ -n "${ZSH_TMUX_MODE}" ]]; then
			if [[ -f "${DIRSFILE}" ]]; then
				dirstack=( ${(f)"$(< "${DIRSFILE}")"} )
				local last_dir="${dirstack[${#dirstack}]}"
				[[ -d "${last_dir}" ]] && cd "${last_dir}"
			fi
		fi
	# Else (initial entry), create the history and dirstack files.
	elif [[ -z "${ZSH_TMUX_PATH_OLD}" ]]; then
		echo "DEBUG: _normally_, this is initial tracking"
		HISTFILE="${ZT_BASE_PATH}/${ZSH_TMUX_PATH}/histfile"
		DIRSFILE="${ZT_BASE_PATH}/${ZSH_TMUX_PATH}/dirsfile"
		print -lD ${PWD} ${(q)dirstack} > "${DIRSFILE}"
		#if [[ ${chpwd_functions[(r)_zsh_tmux_chpwd_hook]} != _zsh_tmux_chpwd_hook ]]; then
		#	chpwd_functions+=(_zsh_tmux_chpwd_hook)
		#fi
		add-zsh-hook chpwd _zsh_tmux_chpwd_hook
		#if [[ ${zshexit_functions[(r)_zsh_tmux_zshexit_hook]} != _zsh_tmux_zshexit_hook ]]; then
		#	zshexit_functions+=(_zsh_tmux_zshexit_hook)
		#fi
		#>>TODO: This is called even when we kill the session. I don't know if I want that...
#		add-zsh-hook zshexit _zsh_tmux_zshexit_hook
		#<<TODO
	fi
	echo "DEBUG: reschedule"
	sched +00:01:00 _zsh_tmux_track_pane
}
function _zsh_tmux_restore_session ()	{
	echo "Going for restore. This should be locked against multiple entry."
	local ZT_SESSION_ID="$(_zsh_tmux_get_session_id)"
	local ZT_SESSION_NAME="$(_zsh_tmux_get_session_name)"
	#_zsh_tmux_lock_dir "${ZT_SESSION_ID}.lock"
	_zsh_tmux_lock_dir "${ZT_SESSION_ID}.restore_lock"
	# If there is a log of the session being restored after it has been logged as initiated, do not restore it.
	# : This covers the scenario where more than one pane discover they are running under an untracked session and try to restore it.
	if _zsh_tmux_check_restore "${ZT_SESSION_NAME}"; then
		echo "restoring"
		# Set ZSH_TMUX_MODE to restore, so that panes know they are in restore mode.
		ZSH_TMUX_MODE="restore"
		# Rename the session_id directory to the new session id.
		local ZT_SESSION_ID_OLD="$(readlin\k "${ZT_BASE_PATH}/${ZT_SESSION_NAME}")"
		if [[ "${ZT_SESSION_ID_OLD}" != "${ZT_SESSION_ID}" ]]; then
			_zsh_tmux_lock_dir "${ZT_SESSION_ID}.session_lock"
			mv "${ZT_BASE_PATH}/${ZT_SESSION_ID_OLD}" "${ZT_BASE_PATH}/${ZT_SESSION_ID}"
			\ln --symbolic --no-dereference --force "${ZT_SESSION_ID}" "${ZT_BASE_PATH}/${ZT_SESSION_NAME}"
			_zsh_tmux_unlock_dir "${ZT_SESSION_ID}.session_lock"
		fi
		# Save the restorer's zsh_tmux_path, and restore it after the loop.
		local ZSH_TMUX_PATH_SAVED="${ZSH_TMUX_PATH}"
		# For each window, for each pane, set ZSH_TMUX_PATH to the proper value (which will be inherited and handled in the child shell's ZSH_TMUX_PATH_OLD handling in _zsh_tmux_track_pane), and issue the proper tmux commands  to spawn them.
		pushd -q "${ZT_BASE_PATH}/${ZT_SESSION_ID}"
		# Why doesn't assigning the result of splitting the directory globbing to a variable work?
		#local windows_list=( ${(pws: :)"$(print \@[[:digit:]](#c1,)(/N^MT))"} )
		for window_i in ${(pws: :)"$(print \@[[:digit:]](#c1,)(/N^MT))"}; do
			pushd -q "${window_i}"
			# Make a list of the windows panes.
			#...
			#local panes_list=(${(pws: :)"$(print \%[[:digit:]](#c1,)(/N^MT))"})
			for pane_i in ${(pws: :)"$(print \%[[:digit:]](#c1,)(/N^MT))"}; do
				ZSH_TMUX_PATH="${ZT_SESSION_ID}/${window_i}/${pane_i}"
				echo "${ZSH_TMUX_PATH}"
				#...
			done
			# TODO: Hash can be calculated with a script with "tcc -run" hashbang.
			#...
			popd -q
		done
		popd -q
		#...
		# Restore zsh_tmux_path (in case it is set).
		ZSH_TMUX_PATH="${ZSH_TMUX_PATH_SAVED}"
		# Log restore time.
		_zsh_tmux_log_restore_time "${ZT_BASE_PATH}/${ZT_SESSION_NAME}.log"
		# Reset restore mode.
		unset ZSH_TMUX_MODE
	fi
	_zsh_tmux_unlock_dir "${ZT_SESSION_ID}.restore_lock"
	#_zsh_tmux_unlock_dir "${ZT_SESSION_ID}.lock"
}
#DEBUGGING
functions -T _zsh_tmux_get_{{session,window,pane}_id,{session,window}_name} _zsh_tmux_get_last_{create,restore}_time _zsh_tmux_check_{window_hardnamed,restore} _zsh_tmux_{,un}lock_dir _zsh_tmux_log_{restore,dummy}_time _zsh_tmux_sched_callback _zsh_tmux_{chpwd,zshexit}_hook _zsh_tmux_{track_pane,restore_session}
# : Main
#Make these env variables uninheritable to subprocesses.
#typeset +gx ZSH_TMUX_INSIDE ZSH_TMUX_PATH
typeset +gx ZSH_TMUX_INSIDE
function {
	# Inside tmux:
	if [[ "${ZSH_TMUX_INSIDE}" = "true" ]]; then
		_zsh_tmux_sched_callback
	# Outside tmux:
	else
		add-zsh-hook -d chpwd _zsh_tmux_chpwd_hook
		add-zsh-hook -d zshexit _zsh_tmux_zshexit_hook
	fi
}
