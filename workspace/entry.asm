.model tiny

.stack 100h
 
.data
    filename db "D:\file.txt", 0
    error_file_nf db "file not found", 0
    buffer_size equ 10000
    err_length equ 15
    buffer db buffer_size dup(0) 
    file_descriptor dw 0
    bytes_read dw 0
    
.code
main proc
    mov ax, @data
    mov ds, ax

open_file:
    mov ah, 3dh ; syscall open file
    mov al, 0 ; read-only
    lea dx, filename 
    int 21h
    call check_error
    mov file_descriptor, ax 
    
read_file:
    mov ah, 3fh ; syscall read file
    mov bx, file_descriptor
    mov cx, buffer_size ; bytes to read
    lea dx, buffer ; to read into buffer
    int 21h
    call check_error
    mov bytes_read, ax
    
write_stdout:
    mov ah, 40h ; syscall write file
    mov bx, 1 ; to stdout
    mov cx, bytes_read ; number of bytes to write
    lea dx, buffer ; from buffer
    int 21h
    call check_error
    
exit:
    mov ah, 4ch
    int 21h
    
check_error proc
    jnc no_error ; if error happened, carry flag is set
    mov ah, 40h ; write
    mov bx, 1 ; to stdout
    mov cx, err_length ; error msg length
    lea dx, error_file_nf ; from error msg
    int 21h
    mov ah, 4ch
    int 21h
    no_error:
        ret
check_error endp

main endp
end main

;.bss
    ;buffer resb buffer_size
    ;file_descriptor resw 1
    ;bytes_read resw 1