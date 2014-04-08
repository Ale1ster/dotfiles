# This part of the file contains temporary aliases used for transitioning. First use was for dvorak migration.

# Set the keyboard map to dvorak international without dead keys and play ball. Afterwards reset it to the previous state (note: 
function learn () {
	#Inhibit calls on ttys.
	if [[ -z "$DISPLAY" ]]; then
		echo "Hey! No changing keymaps in ttys!"
		return 1
	fi

	setxkbmap -option "" -option "grp:switch,grp:alt_shift_toggle,grp_led:scroll" -layout "us" -variant "dvorak-alt-intl"
	dvorak7min
	setxkbmap -option "" -option "grp:switch,grp:alt_shift_toggle,grp_led:scroll" -layout "us,gr,jp" -variant ",,"
}
