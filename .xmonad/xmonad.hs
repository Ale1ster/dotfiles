{-# LANGUAGE NoMonomorphismRestriction #-}

import XMonad

import qualified XMonad.StackSet as W
import qualified Data.Map        as M

import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks(manageDocks, avoidStruts)

import XMonad.Util.Run(spawnPipe)
import XMonad.Util.EZConfig
import XMonad.Util.Scratchpad
import XMonad.Util.NamedScratchpad

import XMonad.Layout.IM
import XMonad.Layout.Tabbed
import XMonad.Layout.Grid
import XMonad.Layout.Tabbed
import XMonad.Layout.Circle
import XMonad.Layout.Reflect
import XMonad.Layout.ResizableTile
import XMonad.Layout.PerWorkspace
import XMonad.Layout.Named
import XMonad.Layout.LayoutHints
import XMonad.Layout.NoBorders
import XMonad.Layout.WindowNavigation
import XMonad.Layout.PerWorkspace

import XMonad.Actions.CycleWS
import XMonad.Actions.GridSelect

import Data.Ratio((%))
import System.Exit
import System.IO

-- Media Keys (commandlinefu.com/commands/using/amixer)
xF86AudioLowerVolume, xF86AudioRaiseVolume, xF86AudioMute	:: KeySym
xF86AudioLowerVolume	= 0x1008ff11
xF86AudioRaiseVolume	= 0x1008ff13
xF86AudioMute			= 0x1008ff12

-- Terminal
myTerminal	= "urxvt"

-- Workspaces
myWorkspaces	= [ "1:code", "2:web", "3:project", "4:manage", "5:sys", "6:remote", "7:various", "8" ] {- ++ map show [7..8] -} ++ [ "9:fun", "0:im", "NSP" ]

-- Window Border Colors
myNormalBorderColor		= "#3465a4"
myFocusedBorderColor	= "#ff950e"	--"#c02222"	--"#dddddd"

-- Border Size
myBorderWidth	= 1

-- Workspace Switch Keys
myWorkspaceSwitchKeys	= [ xK_1..xK_8 ] ++ [ xK_9, xK_0 ] ++ [xK_minus] -- ++ [ xK_equal ]

-- Key Bindings
myKeys conf@(XConfig {XMonad.modMask = modMask}) = M.fromList $
	[ ((modMask .|. shiftMask, xK_Return), spawn $ XMonad.terminal conf)
	, ((modMask .|. shiftMask, xK_q), io (exitWith ExitSuccess))
	, ((modMask, xK_q), restart "xmonad" True)
	, ((modMask .|. shiftMask, xK_c), kill)
	, ((modMask .|. shiftMask, xK_g), goToSelected defaultGSConfig)
	, ((modMask .|. shiftMask, xK_space), sendMessage FirstLayout)
	, ((modMask, xK_space), sendMessage NextLayout)
	, ((modMask, xK_n), refresh)
	, ((modMask .|. shiftMask, xK_Tab), windows W.focusUp)
	, ((modMask, xK_Tab), windows W.focusDown)
	, ((modMask, xK_k), windows W.focusUp)
	, ((modMask, xK_j), windows W.focusDown)
	, ((modMask, xK_m), windows W.focusMaster)
	, ((modMask .|. shiftMask, xK_k), windows W.swapUp)
	, ((modMask .|. shiftMask, xK_j), windows W.swapDown)
	, ((modMask .|. shiftMask, xK_m), windows W.swapMaster)
	, ((modMask .|. controlMask, xK_Right), nextWS)
	, ((modMask .|. controlMask, xK_Left), prevWS)
	, ((modMask, xK_h), sendMessage Shrink)
	, ((modMask, xK_l), sendMessage Expand)
	{-
--		==	These operations have some redraw bugs...
	, ((modMask .|. shiftMask, xK_t), withFocused $ windows . W.sink)
	, ((modMask, xK_t), withFocused (\windowId -> do  { float windowId } ))
	-}
	, ((modMask, xK_comma), sendMessage (IncMasterN 1))
	, ((modMask, xK_period), sendMessage (IncMasterN (-1)))
	] ++
	[ ((m .|. modMask, k), windows $ f i)
	| (i, k) <- zip (XMonad.workspaces conf) myWorkspaceSwitchKeys
	, (f, m) <- [ (W.greedyView, 0), (W.shift, shiftMask) ]
	] ++
	[ ((0, xF86AudioLowerVolume), spawn "amixer -c 0 set Master 1-")
	, ((0, xF86AudioRaiseVolume), spawn "amixer -c 0 set Master 1+")
	, ((0, xF86AudioMute), spawn "amixer set Master toggle")
	, ((modMask, xK_y), spawn "xinput set-prop 'ETPS/2 Elantech Touchpad' 'Device Enabled' $( echo `xinput list-props 'ETPS/2 Elantech Touchpad' | awk '/Device Enabled/ { print 1 - $4 }'` )")		--For mouse state toggle (enabling/disabling).
	] ++
	[ ((modMask, xK_Return), spawn "xterm -e tmux")
--	, ((modMask, xK_l), spawn "i3lock -n -c 0b3b1b")
	, ((modMask .|. shiftMask, xK_k), spawn "i3lock -n -c 151515")
	, ((modMask .|. shiftMask, xK_l), spawn "i3lock -n -i ~/Pictures/screensaver.png")
	, ((modMask, xK_p), spawn "dmenu_run")
	, ((modMask, xK_f), spawn "firefox > /dev/null")
	, ((modMask, xK_c), spawn "chromium > /dev/null")
	, ((modMask, xK_s), spawn "zsh -c \"xhost +local: && su skype -c 'nohup /usr/bin/skype &'\"")
	, ((0, xK_Print), spawn "scrot -e 'mv $f ~/Pictures/Screenshots'")
	, ((modMask .|. shiftMask, xK_backslash), spawn (myTerminal ++ "-T ncmpcpp -e ncmpcpp"))
	, ((modMask, xK_v), namedScratchpadAction myScratchpads "alsamixer")
	, ((modMask, xK_d), namedScratchpadAction myScratchpads "music")
	, ((modMask, xK_b), namedScratchpadAction myScratchpads "notes")
	, ((modMask, xK_grave), scratchpadSpawnActionTerminal "SCRATCH=1 urxvt -T float_term")
	]

-- Layouts
myTabConfig	= defaultTheme	{ inactiveBorderColor = "#ff0000"
							, activeTextColor = "#00ff00" } 
basicLayout	= smartBorders $ Tall nmaster delta ratio
	where
		nmaster = 1
		delta	= 3/100
		ratio	= 3/5
tallLayout		=	named "||" $ avoidStruts basicLayout
wideLayout		=	named "="  $ avoidStruts $ Mirror basicLayout
gridLayout		=	named "#"  $ avoidStruts Grid
fullLayout		=	named "O"  $ noBorders Full
tabbedLayout	=	named ".." $ avoidStruts $ tabbed shrinkText myTabConfig
imLayout		=	named "-|" $ avoidStruts $ reflectHoriz $ withIM (1%3) skypeRoster basicLayout
	where
		skypeRoster = (ClassName "Skype")  `And` (Not (Title "Options")) `And` (Not (Role "ConversationsWindow")) `And` (Not (Title "Add a Skype Contact")) `And` (Not (Title "File Transfers"))
myBaseLayout	=	tallLayout ||| wideLayout ||| gridLayout ||| tabbedLayout ||| fullLayout
myLayout		=	onWorkspace "0:im" ( imLayout ||| tallLayout ||| tabbedLayout ) $
					onWorkspace "6:remote" ( tabbedLayout ||| fullLayout ||| tallLayout ) $
					myBaseLayout
					

-- Scratchpads
myScratchpads	=
	[ NS "notes" "aterm -T notes -e tmux new-session -s notes \"vim ~/.notes.text\"" (title =? "notes") (customFloating $ W.RationalRect (0.1) (0.15) (0.8) (0.65))	--defaultFloating
	, NS "music" "xterm -T music ncmpcpp" (title =? "music") (customFloating $ W.RationalRect (0.1) (0.15) (0.8) (0.65))
	, NS "alsamixer" "xterm -T volume -e \"sleep 1 && alsamixer\"" (title =? "volume") (customFloating $ W.RationalRect (0.225) (0.175) (0.55) (0.65))
	] where role = stringProperty "WM_WINDOW_ROLE"

-- Manage Hooks
myManageHook	= manageDocks <+> myFloatHook <+> myScratchpadManageHook <+> myNamedScratchpadManageHook -- <+> manageHook defaultConfig
myFloatHook		= composeAll
	[ className =? "Firefox"	-->	moveToWeb
--	, className =? "Firefox"	-->	unfloat
	, className =? "Chromium"	-->	moveToWeb
--	, className =? "Chromium"	-->	unfloat
	, className =? "Skype"		-->	moveToIM
--	, className =? "Skype"		-->	unfloat
	, className =? "X2goclient"	-->	moveToRemote
	, className =? "X2GoAgent"	-->	moveToRemote
	, className =? "mplayer2"	--> doFloat
	, className =? "MPPlaylist"	--> moveToFun
	, className =? "MPPlaylist"	--> unfloat
	, stringProperty "WM_WINDOW_ROLE" =? "CallWindow" --> doFloat
	] where
	unfloat			= ask >>= doF . W.sink
	moveToWeb		= doF $ W.shift "2:web"
	moveToFun		= doF $ W.shift "9:fun"
	moveToIM		= doF $ W.shift "0:im"
	moveToRemote	= doF $ W.shift "6:remote"
myNamedScratchpadManageHook	= namedScratchpadManageHook myScratchpads
myScratchpadManageHook		= scratchpadManageHook (W.RationalRect 0.1 0.15 0.8 0.65)
myFocusFollowsMouse			= True

-- Default Stuff
defaults	= defaultConfig
	{ terminal				= myTerminal
	, workspaces			= myWorkspaces
	, modMask				= mod4Mask
	, normalBorderColor		= myNormalBorderColor
	, focusedBorderColor	= myFocusedBorderColor
	, borderWidth			= myBorderWidth
	, manageHook			= myManageHook
	, layoutHook			= myLayout
	, keys					= myKeys
	}

-- Main
main	= do
	xmproc <- spawnPipe "xmobar ~/.xmobarrc"
	xmonad $ defaults
		{ logHook	= dynamicLogWithPP $ xmobarPP
			{ ppOutput	= hPutStrLn xmproc
			, ppSort	= fmap (.scratchpadFilterOutWorkspace) $ ppSort xmobarPP
			, ppTitle	= xmobarColor "green" "" . shorten 50
			}
		}
