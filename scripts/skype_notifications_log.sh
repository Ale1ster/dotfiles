#!/bin/bash

###############################
#   __AVAILABLE VARIABLES__   #
# Notification type: %type    #
# Username: %sskype           #
# Contact name: %sname        #
# Message Contents: %smessage #
# File name: %fname           #
# File path: %fpath           #
# File size: %fsize           #
###############################

# Enter as notification script in skype: 
# ~/scripts/skype_notifications_log.sh "%type" "%sskype" "%sname"
echo "$(date +"%F %a %T") $@" >>~/.skype_notifications

# LINKS
# http://community.skype.com/t5/Mac/Variables-in-regards-to-executing-scripts-upon-an-event/td-p/1286444
# http://www.diknows.com/2012/01/hear-skype-chat-in-voice/
