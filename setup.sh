#!/bin/sh

# === This script will be used as a controller for any manual labour needed outside of dotfile installation.

# =1= .Xresources alias files.
# Setup .Xdefaults symlink to .Xresources
if [ ! -f ".Xdefaults" ]; then
	ln -s .Xresources .Xdefaults
fi
#Setup .Xdefaults-$host symlink to .Xdefaults (xterm has a quirk :) )...
xdef_xterm_alias=".Xdefaults-$(uname -n)"
if [ ! -f "$xdef_xterm_alias" ]; then
	ln -s .Xdefaults $xdef_xterm_alias
fi


