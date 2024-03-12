.model tiny
 
.data
    code_buffer_size equ 10001
    data_buffer_size equ 10000
    
    data_pointer dw 0

    code_pointer dw 0
    loop_begin dw 0
    nesting_level dw 0

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
    lea ax, code_buffer
    mov code_pointer, ax
    lea ax, data_buffer
    mov data_pointer, ax
    push code_pointer
    call interpret
    jmp exit

interpret proc
    pop ax ; return address
    pop si ; code pointer
    mov code_pointer, si
    push ax ; place return address back

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
            mov ax, code_pointer
            inc ax
            mov loop_begin, ax

            mov nesting_level, 1
            for_loop:
                inc code_pointer
                brackets_switch:
                    mov bx, code_pointer
                    mov dl, byte ptr ds:[bx]

                    cmp dl, '['
                    je case_brackets_1

                    cmp dl, ']'
                    je case_brackets_2
                    jmp brackets_break

                    case_brackets_1:
                        inc nesting_level
                        jmp brackets_break

                    case_brackets_2:
                        dec nesting_level
                        jmp brackets_break

                    brackets_break:
                        cmp nesting_level, 0
                        jne for_loop

            mov bx, code_pointer
            mov byte ptr ds:[bx], 0

            while_loop:
                mov bx, data_pointer
                mov dx, word ptr ds:[bx]
                cmp dx, 0
                je while_break

                push loop_begin ; save state
                push nesting_level ; save state
                push code_pointer ; save state
                push loop_begin ; argument for interpret
                call interpret
                pop code_pointer ; restore state
                pop nesting_level ; restore state
                pop loop_begin ; restore state
                jmp while_loop

            while_break:
            mov bx, code_pointer
            mov byte ptr ds:[bx], ']'

        break:
            inc code_pointer
            mov bx, code_pointer
            mov ah, byte ptr ds:[bx]
            cmp ah, 0
            ;jne word ptr [interpret_loop] ; long jmp
            ;jne interpret_loop
            je skip
            jmp interpret_loop
            skip:
            ret
            
interpret endp

exit:
    mov ah, 4ch
    int 21h

end start