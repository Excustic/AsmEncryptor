;Made by Michael Kushnir 2018
;The program below is a final project in turbo assembly, it can encrypt a file in different methods and an encrypted copy will be saved later
;*To encrypt a file, it has to be saved in C:/TASM so the program could read, otherwise it won't find it
IDEAL
MODEL small
STACK 100h
DATASEG
Savedkey dw ''
EndString2 dw '$'
NewFile db 'C:/TASM/MyEnc.txt',0 ;configure the path where your file will be saved
Msg1 db 'File name:$'
Msg2 db 10,13,'Encryption done$'
Msg3 db 10,13,'Choose a method of encryption:',10,13,'1.Low Security - Increments the value of each letter',10,13,'2.Medium Security - Seperates the alphabet in two halves and swaps letters in the same position',10,13,'3.High Security - A one-time pad encryption that uses the name of the file as the keyword',10,13,'$'
Msg4 db 10,13,'A file by the name of "MyEnc" should be saved in the path you configured (by default C:/TASM)$'
ErrorMsg db 'The file could not be opened',10,13,'$'
ErrorMsg2 db 'The Encrypted version of the file couldnt be created$'
Input dw '','$'
EndString db '$$$$$$$'
FileHandle dw 0
NumOfBytes dw 0

Buffer dw ''


CODESEG
 
proc ReadInput
mov bx,offset Input	
xor si,si
ReadLine:
mov ah,1
int 21h
cmp al,8
je delete
cmp al,0Dh
je Stop
mov ah,0
mov [bx+si],ax
inc si
jmp ReadLine
delete:
add si,-1
jmp ReadLine
Stop:
inc si
mov ax,0
mov [bx+si],ax
ret
endp ReadInput

;;;;;;;;;;;;;;;;;;
;;;File Operations
;;;;;;;;;;;;;;;;;;

proc CreateFile
xor ax,ax
mov ah,3Ch
lea dx,[NewFile]
mov cx,0h
int 21h
mov [FileHandle],ax
jc openerror1
jmp endofproc1
openerror1:
mov dx, offset ErrorMsg2
mov ah, 9h
int 21h
mov dx,ax
add dx,48
mov ah,2
int 21h
jmp endofproc1
endofproc1:
 ret
endp CreateFile

proc OpenFile
mov ax, 3D02h
mov dx,offset Input
int 21h
jc openerror
mov [FileHandle], ax
;-----  Get the length of a file by setting a pointer to its end
        mov     ah, 42h
        mov     al ,2
        mov     bx, [FileHandle]
        xor     cx, cx
        xor     dx, dx
        int     21h
        jc      openerror
        cmp     dx,0
        jne     openerror  ;file size exceeds 64K

;-----  Save size of file
        mov     [NumOfBytes], ax

;----- Return a pointer to the beginning of the file
        mov     ah, 42h
        mov     al, 0
        mov     bx, [FileHandle]
        xor     cx, cx
        xor dx, dx
        int 21h
        jc  openerror
		
jmp endofproc
openerror:
mov dx, offset ErrorMsg
mov ah, 9h
int 21h
mov dx,ax
add dx,48
mov ah,2
int 21h
jmp exit
endofproc:
ret 
endp OpenFile
 
 proc ReadFile
mov ah,3Fh
mov bx, [FileHandle]
mov cx,[NumOfBytes]
mov dx,offset Buffer
int 21h
ret
endp ReadFile
 
proc WriteToFile

mov ah,40h
mov bx,[FileHandle]
mov cx,[NumOfBytes]
mov dx,offset Buffer
int 21h
ret
endp WriteToFile

proc CloseFile
mov ah,3Eh 
mov bx, [FileHandle]
int 21h
ret
endp CloseFile

;;;;;;;;;;;;;;;
;;;;Encryptions
;;;;;;;;;;;;;;;

proc incletters
xor si,si
mov cx,[NumOfBytes] 
doinc:
mov bx,offset Buffer
mov ax,0
mov dl,20h ;code ignores space character
cmp [bx+si],dl
je dontdo
mov ax,1
dontdo:
add [bx+si],ax ;if the character is a space character then no value will be added otherwise the value of the character will be incremented
inc si
loop doinc
ret
endp incletters

proc swapletters
xor si,si
mov cx,[NumOfBytes]
mov bx,offset Buffer
doswap:
mov dl,20h ;code ignores space character
cmp [bx+si],dl
je dontswap
mov dl,91
cmp [bx+si],dl
jb CapitalLetter
mov dl,110 ;separation of the alphabet to groups of a-n and m-z
cmp [bx+si],dl
jge subtract
mov ax,13
jmp swap
CapitalLetter:
mov dl,78 ;separation of the alphabet to groups of A-N and M-Z
cmp [bx+si],dl
jge subtract
mov ax,13
jmp swap
subtract:
mov ax,-13
swap:
add [bx+si],ax
dontswap:
inc si
loop doswap
ret
endp swapletters

proc FileKey
xor ax,ax
mov si,-1
mov di,-1
mov cx,[NumOfBytes]
doKey: ;Finds the value that will be added to a character
mov dl,2Eh ;code ignores the character '.' and everyhing after it as we only want the name of the file and not the name and the extension after it
inc si
mov bx,offset Input
cmp [bx+si],dl
je reset 
inc di
xor dx,dx
mov dl,[bx+si]
cmp dl,97 ; 97='a' in ASCII
jge notCapital
sub dl,64 ;We want to know the number of the letter in the alphabetical order so we need to subtract it by a certain value because letters do not appear first in ASCII code order
jmp AddValue
notCapital:
sub dl,96 ;We want to know the number of the letter in the alphabetical order so we need to subtract it by a certain value because letters do not appear first in ASCII code order
AddValue: ;Adds the value and checks if the output letter is in a fixed position
mov bx,offset Buffer
mov al,91
cmp [bx+di],al
jb Capital
add [bx+di],dl
;find whether a value is a letter in ASCII or other character
mov dl,122
cmp [bx+di],dl
ja reorder
jmp endofloop
Capital:
add [bx+di],dl
mov al,32
add al,dl
cmp [bx+di],al
je dontchange
;find whether a value is a letter in ASCII or other character
mov dl,90
cmp [bx+di],dl
ja reorder
jmp endofloop
reorder:
mov dl,26
sub [bx+di],dl
jmp endofloop
dontchange:
sub [bx+di],dl
dec si
jmp endofloop
reset:
inc cx
mov si,-1
endofloop:
loop doKey
ret
endp FileKey

start:

mov ax, @data
mov ds, ax

mov dx, offset Msg1
mov ah,9
int 21h

call ReadInput
call OpenFile
call ReadFile
call CloseFile
call CreateFile

xor dx,dx
mov dx,offset Msg3
xor ax,ax
mov ah,9
int 21h

Choice:
mov ah,2
mov dx,10
int 21h
mov ah,2
mov dx,13
int 21h
mov ah,1
int 21h
cmp al,'3'
ja Choice
cmp al,'1'
jb Choice
cmp al,'1'
je UseMethod1
cmp al,'2'
je UseMethod2
call FileKey
jmp ChoiceMade
UseMethod1:
call incletters
jmp ChoiceMade
UseMethod2:
call swapletters

ChoiceMade:
call WriteToFile
call CloseFile

mov dx,offset Msg2
mov ah,9
int 21h
mov dx,offset Msg4
mov ah,9
int 21h
exit:
mov ax, 4c00h
int 21h
END start