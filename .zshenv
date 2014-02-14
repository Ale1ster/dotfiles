# .zsh base directory
export ZDOTDIR="$HOME/.zshore"

# Path variable
export PATH="$HOME/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:/opt/bin:/usr/vin/vendor_perl:/usr/bin/core_perl:${HOME}/.perl5/bin"

# Something seems to be wrong with zsh; it doesn't load zshenv, so I source it from zshrc.
export ZSHENV_SOURCED="true"
