#!/bin/sh

# =1= .Xresources alias files.
# Setup .Xdefaults symlink to .Xresources
ln -s .Xresources .Xdefaults
#Setup .Xdefaults-$host symlink to .Xdefaults (xterm has a quirk :) )...
ln -s .Xdefaults ".Xdefaults-$(uname -n)"


