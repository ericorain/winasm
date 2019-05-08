.386
.model flat,stdcall
option casemap:none
DlgProc proto :DWORD,:DWORD,:DWORD,:DWORD

include windows.inc
include user32.inc
include kernel32.inc
includelib user32.lib
includelib kernel32.lib
includelib winmm.lib

include Inc\ufmod.inc
includelib Lib\ufmod.lib

.const
WOJTEK equ 100


.data
DlgName db "MyDialog",0

.data?
hInstance HINSTANCE ?


.code
start:
	invoke GetModuleHandle, NULL
	mov hInstance,eax
	invoke DialogBoxParam, hInstance, ADDR DlgName,NULL, addr DlgProc, NULL
	invoke ExitProcess,eax

DlgProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
	.IF uMsg==WM_INITDIALOG
		
		; Start playback.
		invoke uFMOD_PlaySong,WOJTEK,0,XM_RESOURCE
		
	.ELSEIF uMsg==WM_CLOSE
		
		; Stop playback.
		invoke uFMOD_PlaySong,0,0,0
		
		invoke EndDialog, hWnd,NULL
	.ELSE
		mov eax,FALSE
		ret
	.ENDIF
	mov eax,TRUE
	ret
DlgProc endp
end start
