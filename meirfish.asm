IDEAL
MODEL small
STACK 100h
DATASEG
xsight dw 152
xsightend dw 168
ysight dw 60
ysightend dw 67
color db ?
filename db 'target.bmp',0
filehandle dw ?
Header db 54 dup (0)
Palette db 256*4 dup (0)
ScrLine db 320 dup (0)
ErrorMsg db 'Error', 13, 10 ,'$'
CODESEG
proc OpenFile
; Open file
mov ah, 3Dh
xor al, al
mov dx, offset filename
int 21h
jc openerror
mov [filehandle], ax
ret
openerror :
mov dx, offset ErrorMsg
mov ah, 9h
int 21h
ret
endp OpenFile
proc ReadHeader
; Read BMP file header, 54 bytes
mov ah,3fh
mov bx, [filehandle]
mov cx,54
mov dx,offset Header
int 21h
ret
endp ReadHeader
proc ReadPalette
; Read BMP file color palette, 256 colors * 4 bytes (400h)
mov ah,3fh
mov cx,400h
mov dx,offset Palette
int 21h
ret
endp ReadPalette
proc CopyPal
; Copy the colors palette to the video memory
; The number of the first color should be sent to port 3C8h
; The palette is sent to port 3C9h
mov si,offset Palette
mov cx,256
mov dx,3C8h
mov al,0
; Copy starting color to port 3C8h
out dx,al
; Copy palette itself to port 3C9h
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
rep movsb ; Copy line to the screen
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


proc crosshair
	mov bx, [ysight]
	mov [ysightend], bx
	add [ysightend], 7
	mov bx, [xsight]
	mov [xsightend], bx
	add [xsightend], 16
	push [xsight]
	push [ysight]
	push [ysightend]
	push [xsightend]
	push ax
	push bx
	push cx
	push dx
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
	sub [xsightend], 8d
	sub [ysight], 8d
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
proc movsightup
	inc [ysight]
	inc [ysightend]
	ret
endp
start :
	mov ax, @data
	mov ds, ax
	; Graphic mode
	mov ax, 13h
	int 10h
	call OpenFile
	call ReadHeader
	call ReadPalette
	call CopyPal
	call CopyBitmap
	call crosshair

WaitForData :
	mov ah, 1
	int 16h
	jz WaitForData
	mov ah, 0 ; there is a key in the buffer, read it and clear the buffer
	int 16h
	cmp al, 119
	je moveup
	cmp al, 100
	;je moveright
	cmp al,97
	;je moveleft
	cmp al, 116
	;je movdown
	jmp WaitForData

moveup:
	call OpenFile
	call ReadHeader
	call ReadPalette
	call CopyPal
	call CopyBitmap
	sub [ysight], 5
	call crosshair
	jmp WaitForData



	mov ax, 3h
	int 10h


exit :
mov ax, 4c00h
int 21h
END start