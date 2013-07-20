#!/bin/sh


######################################################
# TODO: REMOVE backgrounding when running daemons!!! #
######################################################


# == Instead of creating /etc/xprofile, run from here (relevant exports are in .zshrc):\
# Input Method
scim -d

# ==

# Background
#feh --bg-scale ~/.Wallpapers/277_size_1366x768_89.jpg &
feh --bg-scale ~/Pictures/Wallpapers/hd_1366_x_768_taringa.jpg &

# Music server (mpd)
/usr/lib/systemd/systemd --user &

# Xdefaults
xrdb -merge ~/.Xdefaults

# Pointer setup (previous: left_ptr, crosshair)
xsetroot -cursor_name tcross &
# Hide pointer when idle
unclutter &
# Move pointer to avoid problems with UpdatePointer
xdotool mousemove 2000 0
# Disable touchpad while typing
syndaemon -k -i 1 -d #&

# Keyboard setup
#setxkbmap -option "grp:switch,grp:alt_shift_toggle,grp_led:scroll" -layout "us,gr,jp" -variant ",,kana" &
setxkbmap -option "grp:switch,grp:alt_shift_toggle,grp_led:scroll" -layout "us,gr,jp" &

# Composite window manager
xmcompmgr -c &
# Conky
conky &

# Set keyboard shortcuts for switching languages
#	setxkbmap -option "grp:switch,grp:alt_shift_toggle,grp_led:scroll" -layout "us,gr" &
# Auto setup of brightness/color according to time
#	<<not in repos?>>flux  /dev/null 2>&1

# Trayer
exec trayer --edge top --align center --SetDockType true --SetPartialStrut true --expand true --transparent true --alpha 0 --tint 0x000000 --width 6 --height 16 &

# Main
exec /usr/bin/xmonad
