# ==== ls ====

#export LS_COLORS="fi=0:di=34:ln=36:or=31:mi=33:ex=32:so=90:pi=35:cd=1;93:bd=1;31:"

# ==== grep ====

export GREP_OPTIONS="--binary-files=without-match --line-number --ignore-case --color=auto"
export GREP_COLORS="ms=01;34:mc=01;31:sl=:cx=:fn=35:ln=32:bn=32:se=36"

# ==== less ====

# setaf/setab colors:: black(0), red(1), green(2), yellow(3), blue(4), magenta(5), cyan(6), white(7).
# setf/setb colors:: black(0), blue(1), green(2), cyan(3), red(4), magenta(5), yellow(6), white(7).
export LESS_TERMCAP_mb=$(tput setaf 2)								# start blinking
export LESS_TERMCAP_md=$(tput setaf 6)								# start bold mode
export LESS_TERMCAP_me=$(tput sgr0)									# end all mode like so,us,mb,md,mr
#export LESS_TERMCAP_so=$(tput smso; tput bold; tput setaf 4; tput setab 3)
export LESS_TERMCAP_so=$(tput bold; tput setaf 1)					# start standout mode (smso)
export LESS_TERMCAP_se=$(tput sgr0)									# end standout mode (rmso)
export LESS_TERMCAP_us=$(tput setaf 5)								# start underlining (smul)
export LESS_TERMCAP_ue=$(tput rmul; tput sgr0)						# end underlining (rmul)
export LESS_TERMCAP_mr=$(tput rev)									# start reverse mode
export LESS_TERMCAP_mh=$(tput dim)									# start half bright mode
export LESS_TERMCAP_ZN=$(tput ssubm)								# enter subscript mode
export LESS_TERMCAP_ZV=$(tput rsubm)								# end subscript mode
export LESS_TERMCAP_ZO=$(tput ssupm)								# enter superscript mode
export LESS_TERMCAP_ZW=$(tput rsupm)								# end superscript mode

# ==== nmon ====

export NMON="cmknt"

# ==== IM (scim) ====

export XMODIFIERS="@im=SCIM"
export GTK_IM_MODULE="scim"
export QT_IM_MODULE="scim"

# ==== Perl (cpan) ====

export PERL5LIB="~/.perl5/lib/perl5${PERL5LIB:+:$PERL5LIB}"
export PERL_LOCAL_LIB_ROOT="~/.perl5${PERL_LOCAL_LIB_ROOT:+:$PERL_LOCAL_LIB_ROOT}"
export PERL_MM_OPT="INSTALL_BASE=~/.perl5"
export PERL_MB_OPT="--install_base ~/.perl5"
