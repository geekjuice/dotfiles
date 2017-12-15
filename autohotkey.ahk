#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; Remap Capslock to Ctrl
Capslock::Ctrl

; Remap LCtrl+{h,j,k,l} to arrow keys
<^h:: Send {Left}
<^j:: Send {Down}
<^k:: Send {Up}
<^l:: Send {Right}
