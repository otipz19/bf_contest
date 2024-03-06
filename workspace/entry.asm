.model tiny

;.stack 100h
 
; .data
;     filename db "D:\file.txt", 0
;     error_file_nf db "file not found", 0
;     code_buffer_size equ 10000
;     data_buffer_size equ 10000
;     err_length equ 15

;     code_buffer db code_buffer_size dup(0)
;     data_buffer db data_buffer_size dup(0)
;     file_descriptor dw 0
;     code_read dw 0
    
.code
org 100h

start:
    ;mov ax, @data
    ;mov ds, ax

    ; mov ah, 62h ; get psp address
    ; int 21h
    ; mov dx, bx ; psp address is returned in bx
    ; add dx, 81h
    ; mov cx, bx
    ; add cx, ds:[bx + 80h]
    ; add bx, cx
    ; mov ds:[bx], '$'

    mov ah, 40h ; write
    mov bx, 1 ; to stdout
    mov dx, 82h
    mov cl, ds:[80h]
    xor ch, ch
    int 21h
    mov ah, 4ch
    int 21h

; open_file:
;     mov ah, 3dh ; syscall open file
;     mov al, 0 ; read-only
;     ;lea dx, filename
;     mov dx, 81h ; address at which command line is stored 
;     int 21h
;     call check_error
;     mov file_descriptor, ax 
    
; read_file:
;     mov ah, 3fh ; syscall read file
;     mov bx, file_descriptor
;     mov cx, code_buffer_size ; bytes to read
;     lea dx, code_buffer ; to read into code_buffer
;     int 21h
;     call check_error
;     mov code_read, ax
    
; write_stout:
;     mov ah, 40h ; syscall write file
;     mov bx, 1 ; to stdout
;     mov cx, code_read ; number of bytes to write
;     lea dx, code_buffer ; from code_buffer
;     int 21h
;     call check_error
    
; exit:
;     mov ah, 4ch
;     int 21h
    
; check_error proc
;     jnc no_error ; if error happened, carry flag is set
;     mov ah, 40h ; write
;     mov bx, 1 ; to stdout
;     mov cx, err_length ; error msg length
;     lea dx, error_file_nf ; from error msg
;     int 21h
;     mov ah, 4ch
;     int 21h
;     no_error:
;         ret
; check_error endp

end start

;.bss
    ;code_buffer resb code_buffer_size
    ;file_descriptor resw 1
    ;code_read resw 1