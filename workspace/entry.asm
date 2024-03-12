.model tiny
 
.data
    code_buffer_size equ 10001
    data_buffer_size equ 10000
    
    code_buffer db code_buffer_size dup(?) ; BYTE!
    data_buffer dw data_buffer_size dup(?) ; WORD!

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
    mov bx, ax ; save file descriptor
 
read_file:
    mov ah, 3fh ; syscall read file
    mov cx, code_buffer_size ; bytes to read
    lea dx, code_buffer ; to read into code_buffer
    int 21h

place_null:
    lea bx, code_buffer
    add bx, ax ; in ax - count of bytes read from file
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
    lea di, data_buffer
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
            dec di
            dec di
            jmp break

        case_2:
            inc di
            inc di
            jmp break

        case_3:
            inc word ptr ds:[di]
            jmp break

        case_4:
            dec word ptr ds:[di]
            jmp break

        case_5:
            enter_write_check:
                ; if 0Ah at di
                cmp word ptr ds:[di], 0Ah
                jne write_char
                ; write also 0Dh to stdout
                mov ah, 02h ; write char in dl to stdout
                mov dl, 0Dh
                int 21h
            write_char:
                mov ah, 40h ; syscall write file
                mov bx, 1 ; to stdout
                mov cx, 1 ; number of bytes to write
                mov dx, di ; by current pointer
                int 21h
                jmp break

        case_6:
            mov ah, 3fh ; syscall read file
            mov bx, 0 ; from stdin
            mov cx, 1 ; bytes to read
            mov dx, di ; to current pointer
            int 21h
            
            enter_check:
                cmp word ptr ds:[di], 0Dh
                jne eof_check
                ; if read 0Dh, read again to get only 0Ah
                mov ah, 3fh ; syscall read file
                mov bx, 0 ; from stdin
                mov cx, 1 ; bytes to read
                mov dx, di ; to current pointer
                int 21h

            eof_check:
                cmp ax, 0 ; if EOF - ax == 0
                je if_eof
                jmp break
                if_eof:
                mov word ptr ds:[di], -1
                jmp break

            jmp break
        
        case_7:
            mov bp, si
            inc bp

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
                mov dx, word ptr ds:[di]
                cmp dx, 0
                je while_break

                push bp ; save state
                push si ; save state
                push bp ; argument for interpret
                call interpret
                pop si ; restore state
                pop bp ; restore state
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