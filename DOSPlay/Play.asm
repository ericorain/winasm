
include masm32rt.inc
include winmm.inc
includelib kernel32.lib
includelib masm32.lib
includelib winmm.lib

include Inc\ufmod.inc
includelib Lib\ufmod.lib


;; To debug
;dw2hex PROTO :DWORD,:DWORD
;;include masm32.inc
;;includelib masm32.lib
;include debug.inc
;includelib debug.lib

PlayMCIFunc proto :DWORD,:BYTE

.const
BUFFERARGUMENTSSIZE equ 256
BUFFERSIZE equ 17
MYICON equ 100
XMTEST equ 101

.data
CommandLineText db "Play a music or a XM Module",0Dh,0Ah,0Dh,0Ah,"Play filename [/H] [/L] [/T] [/V]",0Dh,0Ah,0Dh,0Ah,"  /H Help",0Dh,0Ah,"  /L Loop",0Dh,0Ah,"  /T Test",0Dh,0Ah,"  /V Version",0Dh,0Ah,0
VersionText db "DOS Player Version 1.0 - (C) La Hire 2009",0
FormatText db "%S",0
ModuleNameText db "Module name: [",0
EndModuleNameText db "]",0Dh,0Ah
PlayingText db "Playing ",0
HelpParameterText db "/H",0
LoopParameterText db "/L",0
TestParameterText db "/T",0
VersionParameterText db "/V",0
ErrorCannotPlayFile db "Error: Cannot play the file",0
ErrorCannotPlayXMModuleFile db "Error: Cannot play the XM module",0
ErrorCannotOpenFile db "Error: Cannot open the file",0
ErrorCannotReadFile db "Error: Cannot read the file",0
ExtendedModuleText db "Extended Module: ",0
Result db 0
LoopOK db 0

OpenText db "open ",22h,0
AliasText db 22h," alias MuSiC",0
PlayMCIText db "play MuSiC repeat",0

.data?
NumberOfArguments DWORD ?
hFile HANDLE ?
SizeReadWrite DWORD ?
AddrBufferArguments DWORD ?

BufferArguments db BUFFERARGUMENTSSIZE DUP(?)
BufferOtherArguments db BUFFERARGUMENTSSIZE DUP(?)
BufferHeader db BUFFERSIZE+1 DUP(?)


.code
start:	

	; Get the command line parameters
	invoke GetCommandLineW
	
	; Get the argument parameters
	invoke CommandLineToArgvW,eax,ADDR NumberOfArguments
	
	; Arguments ?
	.IF NumberOfArguments<2
		
		; No parameter entered
		
GotoHelp:
		
		; Display the commands
		invoke StdOut,ADDR CommandLineText
		
	.ELSE
		
		lea ebx,[eax+4]
		sub NumberOfArguments,1
		mov AddrBufferArguments,OFFSET BufferArguments
		
		; Get the parameters
		.WHILE NumberOfArguments
			
			mov eax,[ebx]
			push ebx
			
			; Convert the Unicode text of the parameter to ANSI
			invoke wsprintf,AddrBufferArguments,ADDR FormatText,eax
			
			; Loop parameter?
			invoke lstrcmp,AddrBufferArguments,ADDR LoopParameterText
			
			; Loop parameter OK
			.IF !eax
				
				; Yes
				mov LoopOK,1
				
			.ELSE
				
				; Version parameter?
				
				invoke lstrcmp,AddrBufferArguments,ADDR VersionParameterText
				
				.IF !eax
					
					; Display the version
					invoke StdOut,ADDR VersionText
					jmp GotoExit
					
				.ELSE
					
					; Help parameter?
					
					invoke lstrcmp,AddrBufferArguments,ADDR HelpParameterText
					
					.IF !eax
						
						; Display the help
						jmp GotoHelp
						
					.ELSE
						
						; Test parameter?
						
						invoke lstrcmp,AddrBufferArguments,ADDR TestParameterText
						
						.IF !eax
							
							; Run the test sound
							
							; Prepare the text "Test"
							mov dword ptr [BufferArguments],"tseT"
							mov byte ptr [BufferArguments+4],00h
							
							; The XM resource is used
							push XM_RESOURCE
							push 0
							push XMTEST
							jmp PlayXM
							
						.ENDIF
						
					.ENDIF
					
					
				.ENDIF
				
				; The other parameters are in another buffer
				mov AddrBufferArguments,OFFSET BufferOtherArguments
				
			.ENDIF
			
			pop ebx
			add ebx,4
			sub NumberOfArguments,1
			
		.ENDW
		
		
		; Open the file to check if it is a XM module
		invoke CreateFile,ADDR BufferArguments,GENERIC_READ,NULL,NULL,OPEN_EXISTING,NULL,NULL 
		
		.IF eax!=INVALID_HANDLE_VALUE
			
			; Save the handle of the file
			mov hFile,eax
			
			; File size
			invoke GetFileSize,eax,NULL
			
			; More than 17 bytes ?
			.IF eax>17
				
				; Yes
				
				; File reading
				invoke ReadFile,hFile,ADDR BufferHeader,BUFFERSIZE,ADDR SizeReadWrite,NULL
				
				.IF eax
					; File read
					mov byte ptr [BufferHeader+BUFFERSIZE],00h
					
					; "Extended Module: " ?
					invoke lstrcmp,ADDR BufferHeader,ADDR ExtendedModuleText
					
					.IF !eax
						;  XM module
						mov Result,1
						
					.ELSE
						; Not a XM module
						mov Result,2
					.ENDIF
					
				.ELSE
					
					; Error Reading the file
					
					; Display the error message
					invoke StdOut,ADDR ErrorCannotReadFile
					
				.ENDIF
				
			.ELSE
				
				; Not a XM module
				mov Result,2
			.ENDIF
			
			; Close the file
			invoke CloseHandle,hFile
			
		.ELSE
			
			; Error Opening the file
			
			; Display the error message
			invoke StdOut,ADDR ErrorCannotOpenFile
			
		.ENDIF
		
		
		; XM file?
		
		.IF Result==1
			
			; Yes
			
			; A loop?
			.IF LoopOK
				; Yes
				push XM_FILE
			.ELSE
				; No
				push XM_FILE+XM_NOLOOP
			.ENDIF
			
			
			; Play the XM module
			push 0
			push OFFSET BufferArguments
			
PlayXM:
			call uFMOD_PlaySong
			
			; Error ? (wrong filename for instance)
			.IF eax
				; No error
				
				; Get the XM module name
				invoke uFMOD_GetTitle
				push eax
				
				;  "Module name: ["
				invoke StdOut,ADDR ModuleNameText
				
				; Display the module name
				call StdOut
				
				; "]",0Dh,0Ah,"Playing ",0
				invoke StdOut,ADDR EndModuleNameText
				
				; Display the file name
				invoke StdOut,ADDR BufferArguments
				
				; Play till key pressed
				call wait_key
			.ELSE
				; Error
				
				; Display the error message
				invoke StdOut,ADDR ErrorCannotPlayXMModuleFile
			.ENDIF
			
		.ELSEIF Result==2
			
			; Not a XM file
			
			; Play using MCI
			invoke PlayMCIFunc,ADDR BufferArguments,LoopOK
			
			; Error ? (wrong filename for instance)
			.IF eax
				; No error
				
				; Display "Playing"
				invoke StdOut,ADDR PlayingText
				
				; Display the file name
				invoke StdOut,ADDR BufferArguments
				
				; Play till key pressed
				call wait_key
			.ELSE
				; Error
				
				; Display the error message
				invoke StdOut,ADDR ErrorCannotPlayFile
			.ENDIF
			
		.ENDIF
		
	.ENDIF
	
GotoExit:
	
	; Exit
	invoke ExitProcess,0
	

PlayMCIFunc proc AddrFileVar:DWORD,LoopVar:BYTE
LOCAL ResultVar:DWORD
	
	; By default there is an error
	mov ResultVar,0
	
	; Creation of the MCI command to open the file
	invoke lstrcpy,ADDR BufferOtherArguments,ADDR OpenText
	invoke lstrcat,ADDR BufferOtherArguments,AddrFileVar
	invoke lstrcat,ADDR BufferOtherArguments,ADDR AliasText
	
	; Command to open the file
	invoke mciSendString,ADDR BufferOtherArguments,NULL,0,NULL
	
	
	; Error?
	.IF !eax
		
		; No error
		
		; A loop ?
		.IF !LoopVar
			
			; No loop
			
			; PlayMCIText db "play MuSiC repeat",0
			mov byte ptr [PlayMCIText+10],al
			
		.ENDIF
		
		; Play the music
		invoke mciSendString,ADDR PlayMCIText,eax,eax,eax
		
		;Error?
		.IF !eax
			
			; No error
			
			; Music playing
			mov ResultVar,1
		.ENDIF
	.ENDIF
	
	mov eax,ResultVar
	Ret
	
PlayMCIFunc endp

end start