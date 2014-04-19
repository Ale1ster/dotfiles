# mkdir and cd there
function mcd () {
	mkdir -p "$1" && cd "$1"
}

# generic open
function open () {
	if [[ -f "$1" ]]; then
		case "$1" in
			*.png | *.jpg | *.jpeg | *.JPG)
				feh "$1" &
				;;
			*.pdf | *.ps | *.djvu)
				zathura --fork "$1"
				;;
#			*.odt | *.doc | *.rtf)				#Mistakes of the past
#				abiword "$1" &> /dev/null &
#				;;
#			*.pps | *.ppt | *.pptx)
#				tonicpoint "$1" &> /dev/null &
#				;;
#			*.mobi | *.epub)
#				FBReader "$1" &> /dev/null &
#				;;
			*.zip | *.rar | *.tar | *.tgz | *.gz | *.bz2)
				echo "That is a compressed file. Are you sure you want to open it?"
				;;
			*)
				vim "$1"
				;;
		esac
	fi
}

# media
function play () {
	if [[ -f "$1" ]]; then
		case "$1" in
			*.mp3 | *.ogg)
				mplayer "$1"
				;;
			*.pls | *.m3u)
				mplayer -playlist "$1"
				;;
			*.mkv | *.avi | *.mp4)
				mplayer "$1"
				;;
			*)
				echo "invalid file extension"
				;;
		esac
	fi
}

# Target setup for X server spawning.
function spawnx () {
	case "$1" in
		#Target 1: X server with XMonad wm.
		"xmonad")
			if [[ -z "$DISPLAY" ]]; then
				startx ~/.xinitrc-xmonad
			else
				echo "[Error] Requested X spawn from within X"
				return 1
			fi
			;;
		#Target 2: X server with dwm.
		"dwm")
			if [[ -z "$DISPLAY" ]]; then
				startx ~/.xinitrc-dwm
			else
				echo "[Error] Requested X spawn from within X"
				return 1
			fi
			;;
		#Target 3: Xephyr server (nested) with dwm.
		"nest")
		echo "Nest is not tested (though it is implemented) yet"
			if [[ -n "$DISPLAY" ]]; then
				XEPHYR_LOC=$(which Xephyr)
				if [[ -n "$XEPHYR_LOC" ]]; then
					echo "Found XEPHYR"
					startx ~/.xinitrc-dwm -- $XEPHYR_LOC -fullscreen -noreset
				else
					echo "[Error] Could not locate Xephyr on PATH"
					return 1
				fi
			else
				echo "[Error] Requested _nested_ X spawn from outside X"
				return 1
			fi
			;;
		*)
			echo "[Error] Unrecognized X spawn option"
			return 1
			;;
	esac
}

# skype wrapper
function skype () {
	xhost +local: && su skype -c "nohup /usr/bin/skype &"
}

# create and chmod +x file (for executable script writing): (mnemonic: Produce eXecutable)
function px () {
	for i in "$@"
	do
		touch "$i" && chmod +x "$i"
	done
}
