.model tiny
 
.data
    code_buffer_size equ 10001
    data_buffer_size equ 10000
    
    data_pointer dw 0

    loop_begin dw 0

    code_buffer db code_buffer_size dup(?) ; BYTE!
    data_buffer dw data_buffer_size dup(?) ; WORD!
    file_descriptor dw 1 dup(?)
    code_read dw 1 dup(?)

.code
org 100h

start:

place_null_char:
    mov cl, ds:[80h]
    xor ch, ch
    mov bx, 81h
    add bx, cx
    mov byte ptr ds:[bx], 0

open_file:
    mov ah, 3dh ; syscall open file
    mov al, 0 ; read-only
    mov dx, 82h ; address at which command line is stored 
    int 21h
    mov file_descriptor, ax 
 
read_file:
    mov ah, 3fh ; syscall read file
    mov bx, file_descriptor
    mov cx, code_buffer_size ; bytes to read
    lea dx, code_buffer ; to read into code_buffer
    int 21h
    mov code_read, ax

place_null:
    lea bx, code_buffer
    add bx, code_read
    inc bx
    mov ds:[bx], byte ptr 0

init_data_buffer:
    mov bx, 0
    init_data_buffer_loop:
        mov byte ptr ds:[data_buffer + bx], 0
        inc bx
        cmp bx, 20000
        jne init_data_buffer_loop

init_interpret:
    lea si, code_buffer
    lea ax, data_buffer
    mov data_pointer, ax
    push si
    call interpret
    mov ah, 4ch
    int 21h

interpret proc
    pop ax ; return address
    pop si ; code pointer
    push ax ; place return address back

    interpret_loop:
        switch:
            mov dl, byte ptr ds:[si]

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

            cmp dl, '['
            jne skip_case_7
            jmp case_7
            skip_case_7:

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
            enter_write_check:
                ; if 0Ah at data_pointer
                mov bx, data_pointer
                cmp word ptr ds:[bx], 0Ah
                jne write_char
                ; write also 0Dh to stdout
                mov ah, 02h ; write char in dl to stdout
                mov dl, 0Dh
                int 21h
            write_char:
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
            
            enter_check:
                mov bx, data_pointer
                cmp word ptr ds:[bx], 0Dh
                jne eof_check
                ; if read 0Dh, read again to get only 0Ah
                mov ah, 3fh ; syscall read file
                mov bx, 0 ; from stdin
                mov cx, 1 ; bytes to read
                mov dx, data_pointer ; to current pointer
                int 21h

            eof_check:
                cmp ax, 0 ; if EOF - ax == 0
                je if_eof
                jmp break
                if_eof:
                mov bx, data_pointer
                mov word ptr ds:[bx], -1
                jmp break

            jmp break
        
        case_7:
            mov ax, si
            inc ax
            mov loop_begin, ax

            mov cl, 1
            for_loop:
                inc si
                brackets_switch:
                    mov dl, byte ptr ds:[si]

                    cmp dl, '['
                    je case_brackets_1

                    cmp dl, ']'
                    je case_brackets_2
                    jmp brackets_break

                    case_brackets_1:
                        inc cl
                        jmp brackets_break

                    case_brackets_2:
                        dec cl
                        jmp brackets_break

                    brackets_break:
                        cmp cl, 0
                        jne for_loop

            mov byte ptr ds:[si], 0

            while_loop:
                mov bx, data_pointer
                mov dx, word ptr ds:[bx]
                cmp dx, 0
                je while_break

                push loop_begin ; save state
                push si ; save state
                push loop_begin ; argument for interpret
                call interpret
                pop si ; restore state
                pop loop_begin ; restore state
                jmp while_loop

            while_break:
            mov byte ptr ds:[si], ']'

        break:
            inc si
            mov ah, byte ptr ds:[si]
            cmp ah, 0
            je skip
            jmp interpret_loop
            skip:
            ret
            
interpret endp

end start