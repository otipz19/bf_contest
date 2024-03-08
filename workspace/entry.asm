.model tiny

;.stack 100h
 
.data
    error_file_nf db "file not found", 0
    error_read db "error read", 0
    err_read_length equ ($ - error_read)
    err_length equ 15

    code_buffer_size equ 10000
    data_buffer_size equ 10000

    code_buffer db code_buffer_size dup(?) ; BYTE!
    data_buffer dw data_buffer_size dup(?) ; WORD!
    file_descriptor dw 1 dup(?)
    code_read dw 1 dup(?)
    
    code_pointer dw 0
    data_pointer dw 0

    counter dw 0
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
    mov file_descriptor, ax 
 
read_file:
    mov ah, 3fh ; syscall read file
    mov bx, file_descriptor
    mov cx, code_buffer_size ; bytes to read
    lea dx, code_buffer ; to read into code_buffer
    int 21h
    call check_error_2
    mov code_read, ax

init_interpret:
    lea ax, code_buffer
    mov code_pointer, ax
    lea ax, data_buffer
    mov data_pointer, ax

interpret:

    interpret_loop:
        switch:
            mov bx, code_pointer
            mov dl, byte ptr ds:[bx]

            cmp dl, '<'
            je case_1

            cmp dl, '>'
            je case_2

            cmp dl, '+'
            je case_3

            cmp dl, '-'
            je case_4

            cmp dl, '.'
            je case_5

            cmp dl, ','
            je case_6

            jmp break

        case_1:
            dec data_pointer
            dec data_pointer
            jmp break

        case_2:
            inc data_pointer
            inc data_pointer
            jmp break

        case_3:
            mov bx, data_pointer
            inc word ptr ds:[bx]
            jmp break

        case_4:
            mov bx, data_pointer
            dec word ptr ds:[bx]
            jmp break

        case_5:
            mov ah, 40h ; syscall write file
            mov bx, 1 ; to stdout
            mov cx, 2 ; number of bytes to write
            mov dx, data_pointer ; by current pointer
            int 21h
            jmp break

        case_6:
            mov ah, 3fh ; syscall read file
            mov bx, 0 ; from stdin
            mov cx, 2 ; bytes to read
            mov dx, data_pointer ; to current pointer
            int 21h
            jmp break
        
        break:
            inc code_pointer
            inc counter
            mov ax, counter
            cmp ax, code_read
            jne interpret_loop
            mov ah, 4ch
            int 21h

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