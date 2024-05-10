IDEAL
MODEL small
STACK 100h
DATASEG
xsight dw 156
xsightend dw 162
ysight dw 60
ysightend dw 62
filename db 'adsoff.bmp',0
filename1 db 'adson.bmp',0
filename2 db 'scope.bmp',0
filehandle dw ?
Header db 54 dup (0)
Palette db 256*4 dup (0)
ScrLine db 320 dup (0)
ErrorMsg db 'Error', 13, 10 ,'$'
HeaderFilter db 54 dup (0)
PaletteFilter db 256*4 dup (0)
ScrLineFilter db 320 dup (0)
ErrorMsgFilter db 'Error', 13, 10 ,'$'
x dw 135
y dw 0
color db 1
yscope dw ?
xscope dw ?
yscopeend dw ?
xscopeend dw ?
adsoff dw 1
rightclickcheck dw 01d
toggleadscheck db 1d
CODESEG
proc OpenFileadsoff
	mov ax, @data
	mov ds, ax
	
	mov ah, 3Dh
	xor al, al
	mov dx, offset filename
	int 21h
	jc openerror
	mov [filehandle], ax
	ret
openerror:
	mov dx, offset ErrorMsg
	mov ah, 9h
	int 21h
	ret
endp OpenFileadsoff

proc OpenFileadson
	mov ax, @data
	mov ds, ax
	
	mov ah, 3Dh
	xor al, al
	mov dx, offset filename1
	int 21h
	jc openerror1
	mov [filehandle], ax
	ret
openerror1:
	mov dx, offset ErrorMsg
	mov ah, 9h
	int 21h
	ret
endp 
proc CloseFile
	mov bx, [filehandle]
	mov ah, 3Eh
	int 21h
	ret
endp


proc OpenFileScope
	mov ax, @data
	mov ds, ax
	
	mov ah, 3Dh
	xor al, al
	mov dx, offset filename2
	int 21h
	jc openerrorScope
	mov [filehandle], ax
	ret
openerrorScope:
	mov dx, offset ErrorMsgFilter
	mov ah, 9h
	int 21h
	ret
endp OpenFileScope
proc ReadHeaderFilter
	mov ah,3fh
	mov bx, [filehandle] ; file handle
	mov cx,54 ; amount of bytes to read
	mov dx,offset HeaderFilter ; where to store
	int 21h
	ret
endp
proc ReadHeader
	mov ah,3fh
	mov bx, [filehandle]
	mov cx,54
	mov dx,offset HeaderFilter
	int 21h
	ret
endp ReadHeader

proc ReadPalette
	mov ah,3fh
	mov cx,400h
	mov dx,offset Palette
	int 21h
	ret
endp ReadPalette

proc ReadPaletteFilter
	mov ah,3fh
	mov cx,400h
	mov dx,offset PaletteFilter
	int 21h
	ret
endp ReadPaletteFilter

proc CopyPal 
	mov si,offset Palette
	mov cx,256
	mov dx,3C8h
	mov al,0
	out dx,al
	inc dx 
	PalLoop:
	; Note: Colors in a BMP file are saved as BGR values rather than RGB .
	mov al,[si+2] ; Get red value .
	shr al,2 ; Max. is 255, but video palette maximal
	; value is 63. Therefore dividing by 4.
	out dx,al ; Send it .
	mov al,[si+1] ; Get green value .
	shr al,2
	out dx,al ; Send it .
	mov al,[si] ; Get blue value .
	shr al,2
	out dx,al ; Send it .
	add si,4 ; Point to next color .
	; (There is a null chr. after every color.)
	loop PalLoop
	ret
endp CopyPal
	

proc CopyBitmap
; BMP graphics are saved upside-down .
; Read the graphic line by line (200 lines in VGA format),
; displaying the lines from bottom to top.
	mov ax, 0A000h
	mov es, ax
	mov cx,200
	PrintBMPLoop :
	push cx
	; di = cx*320, point to the correct screen line
	mov di,cx
	shl cx,6
	shl di,8
	add di,cx
	; Read one line
	mov ah,3fh
	mov cx,320
	mov dx,offset ScrLine
	int 21h
	; Copy one line into video memory
	cld ; Clear direction flag, for movsb
	mov cx,320
	mov si,offset ScrLine
	rep movsb
	 ; Copy line to the screen
	 ;rep movsb is same as the following code :
	 ;mov es:di, ds:si
	 ;inc si
	 ;inc di
	 ;dec cx
	 ;loop until cx=0
	pop cx
	loop PrintBMPLoop
	ret
endp CopyBitmap
proc CopyBitmapFilter
    ; BMP graphics are saved upside-down.
    ; Read the graphic line by line (200 lines in VGA format),
    ; displaying the lines from bottom to top.
    mov ax, 0A000h      ; Set up ES to point to the video memory segment (0A000h)
    mov es, ax

    mov cx, 200
	sub cx, [y]     ; Initialize CX to the number of lines to print (200 lines)

    PrintBMPLoopFilter:
        push cx         ; Save the value of CX on the stack for later use

        ; Calculate the screen line offset (di = cx*320) to point to the correct screen line
        mov di, cx
        shl cx, 6       ; Multiply CX by 64 (320 / 5) to account for VGA screen layout
        shl di, 8       ; Multiply DI by 256 to convert line number to byte offset
        add di, cx 
		add di, [x]    ; Add the result to DI to get the screen line offset

        ; Read one line of pixel data from the file into memory
        mov ah, 3fh         ; DOS function to read from file
        mov cx, 320         ; Number of bytes to read for one line
        mov dx, offset ScrLineFilter; Address of the buffer to store the line data
        int 21h             ; Call DOS interrupt to read the data

        ; Clear the direction flag to set direction for string operations (movsb)
        cld

        ; Set CX to the number of pixels to copy (320 pixels per line)
        mov cx, 320

        ; Set SI to point to the start of the line buffer
        mov si, offset ScrLineFilter

        ; Copy one line of pixel data from the buffer to video memory, 
        ; skipping pixels with color index 255
    NextPixel:
        ; Load the color index of the current pixel
        mov al, [si]

        ; Compare the color index with 255
        cmp al, 255
		

		

        ; If the color index is not 255, copy the pixel to video memory
        jne CopyPixel

        ; If the color index is 255, skip copying this pixel
        jmp SkipPixel

    CopyPixel:
        ; Copy the pixel to video memory
        mov [es:di], al;eurika

    SkipPixel:
        ; Move to the next pixel
        inc si
		; Move to the next pixel
        inc di
        dec cx

        ; Repeat for all pixels in the line
        jnz NextPixel

        ; Restore the value of CX from the stack
        pop cx

    ; Repeat the loop for the next line until all lines are printed
    loop PrintBMPLoopFilter

    ; Return from the procedure
    ret
endp CopyBitmapFilter

proc pictureFilter
	call openfilescope
	call readheaderfilter
	call readpalettefilter
	call copypal
	call copybitmapfilter
	call closefile
endp
proc colorprint
	push ax
	push bx
	push cx
	mov al, 0
	mov cx, [x]
	mov dx, [y]
	mov ah, 0ch
	int 10h
	pop cx
	pop bx
	pop ax
	ret
endp

proc lineX
	push cx
	push [x]
	mov cx, 320
loop4:
	call colorprint
	inc [x]
loop loop4
	pop [x]
	pop cx
	ret
endp

proc triangle
	push cx
	push [y]
	mov cx, 200
loop10:
	call lineX
	inc [y]
loop loop10
	pop [y]
	pop cx
	ret
endp
																												
proc crosshair
	
	push [xsight]
	push [ysight]
	push [ysightend]
	push [xsightend]
	push ax
	push bx
	push cx
	push dx
	mov bx, [ysight]
	mov [ysightend], bx
	add [ysightend], 2
	mov bx, [xsight]
	mov [xsightend], bx
	add [xsightend], 5
	mov [color], 1
drawsightx:
	
	inc [xsight]

	mov al, [color]
	mov cx, [xsight]
	mov dx, [ysight]
	mov bl, 0
	mov ah, 0ch
	int 10h
	mov bx, [xsightend]
	cmp [xsight], bx
	jne drawsightx
	jmp decing
decing:
	sub [xsightend], 2
	sub [ysight], 4
	inc [ysight]
	jmp drawsighty
drawsighty:
	inc [ysight]
	mov al, [color]
	mov cx, [xsightend]
	mov dx, [ysight]
	mov bl, 0
	mov ah, 0ch
	int 10h
	mov bx, [ysightend]
	cmp [ysight], bx
	jne drawsighty
	pop dx
	pop cx
	pop bx
	pop ax
	pop [xsightend]
	pop [ysightend]
	pop [ysight]
	pop [xsight]
	ret
endp


proc movleft
	;call pictureadson
	cmp [x], 15
	jng cont4
	sub [x], 15
cont4:
	call picturefilter
	;call WaitForData
	ret
endp 

proc movright
	call pictureadson
	cmp [x], 305
	jg cont3
	add [x], 15
cont3:
	call picturefilter
	;call WaitForData
	ret
endp

proc movdown
	call pictureadson
	cmp [ysight], 185
	jg cont2
	add [ysight], 5
cont2:
	call picturefilter
	;call WaitForData
	ret
endp

proc moveup
	call pictureadson
	cmp [ysight], 35
	jng cont1
	sub [ysight], 5
cont1:
	call picturefilter
	;call WaitForData
	ret
endp

proc pictureadsoff ;adsoff
	call OpenFileadsoff
	call ReadHeader
	call ReadPalette
	call CopyPal
	call CopyBitmap
	call CloseFile
	ret
endp

proc pictureadson ;adson
	call OpenFileadson
	call ReadHeader
	call ReadPalette
	call CopyPal
	call CopyBitmap
	call CloseFile
	ret
endp



proc mouserightclick
	push ax
	push bx
	
	mov ax,3h
	int 33h

	cmp bx, [rightclickcheck]
	jg toggleads
	je shoote
	jmp endingads
toggleads:
	cmp [toggleadscheck], 1d
	je adson
	call pictureadsoff
	inc [toggleadscheck]
	mov [adsoff], 1
	jmp endingads
adson:
	call pictureadson
	call picturefilter
	dec [adsoff]
	dec [toggleadscheck]
	jmp endingads
shoote:	
	push ax
	push bx
	push cx
	push dx
	push [x]
	call pictureadson
	pop [x]
	pop dx
	pop cx
	pop bx
	pop ax
	cmp [toggleadscheck], 1
	je endingads
mov ax,1h
int 33h

shr cx,1 ; adjust cx to range 0-319, to fit screen
sub dx, 2 ; move one pixel, so the pixel will not be hidden by mouse
mov [x], cx
sub [x] ,15
mov ax, 2h
int 33h
call picturefilter
mov ax,1h
int 33h

endingads:
	
	pop bx
	pop ax

	ret
endp


start :
mov ax, @data
mov ds, ax
; Graphic mode
mov ax, 13h
int 10h
mov ax,0h
	int 33h

; Process BMP file
call pictureadsoff



WaitForData :
ClearBuffer:
    mov ah, 01h  ; Check if a keystroke is available
    int 16h      ; BIOS interrupt to check keyboard status
    jz  EndClear ; If no keystroke is available, exit clearing

    mov ah, 00h  ; Read keystroke
    int 16h      ; BIOS interrupt to read keyboard input

    jmp ClearBuffer ; Continue clearing the buffer

EndClear:
	call mouserightclick
	cmp [adsoff], 1
	je WaitForData
	cmp dl,1d
	je WaitForData
	mov ah, 1
	int 16h
	jz WaitForData
	mov ah, 0 ; there is a key in the buffer, read it and clear the buffer
	int 16h
	cmp al, 113;Mode Q
	je down
	cmp al, 119;Mode W
	je up
	cmp al, 101; Mode E
	je right
	cmp al,97
	je left
	jmp WaitForData

down:
	call movdown
	jmp WaitForData
דup:
	call moveup
	jmp WaitForData
right:
	call movright
	jmp WaitForData
left:
	call movleft
	jmp WaitForData


ending:
	mov ah, 0
	int 16h

	mov ax, 3h
	int 10h


; Wait for key press
mov ah,1
int 21h
; Back to text mode
mov ah, 0
mov al, 2
int 10h

	
exit:
	mov ax, 4c00h
	int 21h
END start


