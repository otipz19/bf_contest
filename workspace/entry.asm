.model tiny

;.stack 100h
 
.data
    error_file_nf db "file not found", 0
    error_read db "error read", 0
    err_read_length equ ($ - error_read)
    err_length equ 15

    code_buffer_size equ 10000
    data_buffer_size equ 10000

    ;code_buffer equ 10000 ; with God help there will be no important data
    code_buffer db 10000 dup(?)
    data_buffer equ 20000
    file_descriptor equ 20001
    code_read equ 20003
    
    code_pointer dw 0
    data_pointer dw 0
.code
org 100h

start:
place_null_char:
    mov cl, ds:[80h]
    xor ch, ch
    mov bx, 81h
    add bx, cx
    mov ds:[bx], 0

open_file:
    mov ah, 3dh ; syscall open file
    mov al, 0 ; read-only
    mov dx, 82h ; address at which command line is stored 
    int 21h
    call check_error_1
    mov ds:[file_descriptor], ax 
    
read_file:
    mov ah, 3fh ; syscall read file
    mov bx, ds:[file_descriptor]
    mov cx, code_buffer_size ; bytes to read
    mov dx, code_buffer ; to read into code_buffer
    int 21h
    call check_error_2
    mov ds:[code_read], ax

init_interpret:
    mov code_pointer, code_buffer
    mov data_pointer, data_buffer

interpret:

    interpret_loop:
        switch:
            mov dx, ds:[code_pointer]

            cmp dx, '<'
            je case_1

            cmp dx, '>'
            je case_2

            cmp dx, '+'
            je case_3

            cmp dx, '-'
            je case_4

            cmp dx, '.'
            je case_5

            cmp dx, ','
            je case_6

            cmp dx, 0
            jne break
            mov ah, 4ch
            int 21h

            ;jmp break

        case_1:
            dec data_pointer
            jmp break

        case_2:
            inc data_pointer
            jmp break

        case_3:
            inc [data_pointer]
            jmp break

        case_4:
            dec [data_pointer]
            jmp break

        case_5:
            mov ah, 40h ; syscall write file
            mov bx, 1 ; to stdout
            mov cx, 1 ; number of bytes to write
            mov dx, data_pointer ; by current pointer
            int 21h
            jmp break

        case_6:
            mov ah, 3fh ; syscall read file
            mov bx, 0 ; from stdin
            mov cx, 1 ; bytes to read
            mov dx, data_pointer ; to current pointer
            int 21h
            jmp break
        
        break:
            inc code_pointer
            jmp interpret_loop
            ;cmp code_pointer, [code_read]
            ;jne interpret_loop
            ;ret
    
; write_stdout:
;     mov ah, 40h ; syscall write file
;     mov bx, 1 ; to stdout
;     mov cx, ds:[code_read] ; number of bytes to write
;     mov dx, code_buffer ; from code_buffer
;     int 21h
;     call check_error
    
exit:
    mov ah, 4ch
    int 21h
    
check_error_1 proc
    jnc no_error_1 ; if error happened, carry flag is set
    mov ah, 40h ; write
    mov bx, 1 ; to stdout
    mov cx, err_length ; error msg length
    lea dx, error_file_nf ; from error msg
    int 21h
    mov ah, 4ch
    int 21h
    no_error_1:
        ret
check_error_1 endp

check_error_2 proc
    jnc no_error_2 ; if error happened, carry flag is set
    mov ah, 40h ; write
    mov bx, 1 ; to stdout
    mov cx, err_read_length ; error msg length
    lea dx, error_read ; from error msg
    int 21h
    mov ah, 4ch
    int 21h
    no_error_2:
        ret
check_error_2 endp


end start