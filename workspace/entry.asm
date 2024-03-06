.model tiny

;.stack 100h
 
.data
    error_file_nf db "file not found", 0
    code_buffer_size equ 10000
    data_buffer_size equ 10000
    err_length equ 15

    code_buffer equ 10000 ; with God help there will be no important data
    data_buffer equ 20000
    file_descriptor equ 20001
    code_read equ 20003
    
.code
org 100h

start:
place_null_char:
    mov cl, ds:[80h]
    xor ch, ch
    mov bx, 82h
    add bx, cx
    mov ds:[bx], 0

open_file:
    mov ah, 3dh ; syscall open file
    mov al, 0 ; read-only
    mov dx, 82h ; address at which command line is stored 
    int 21h
    call check_error
    mov ds:[file_descriptor], ax 
    
read_file:
    mov ah, 3fh ; syscall read file
    mov bx, ds:[file_descriptor]
    mov cx, code_buffer_size ; bytes to read
    mov dx, code_buffer ; to read into code_buffer
    int 21h
    call check_error
    mov ds:[code_read], ax
    
write_stdout:
    mov ah, 40h ; syscall write file
    mov bx, 1 ; to stdout
    mov cx, ds:[code_read] ; number of bytes to write
    mov dx, code_buffer ; from code_buffer
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

end start