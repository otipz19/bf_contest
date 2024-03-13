.model tiny
 
.data
    code_buffer_size equ 10001
    data_buffer_size equ 20000
    code_buffer_offset equ 20000
    data_buffer_offset equ 10000
    
.code
org 100h

start:
    mov si, code_buffer_offset
    mov di, data_buffer_offset

init_buffers:
    mov cx, data_buffer_size + code_buffer_size
    xor ax, ax
    rep stosb
    mov di, data_buffer_offset

place_null_char:
    mov cl, ds:[80h]
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
    mov dx, si ; to read into code_buffer
    int 21h

init_interpret:
    push si
    call interpret
    ret

interpret proc
    pop ax ; return address
    pop si ; code pointer
    push ax ; place return address back

    interpret_loop:
        switch:
            mov al, byte ptr ds:[si]

            cmp al, '<'
            je case_1

            cmp al, '>'
            je case_2

            cmp al, '+'
            je case_3

            cmp al, '-'
            je case_4

            cmp al, '.'
            je case_5

            cmp al, ','
            je case_6

            cmp al, '['
            je case_7

        break:
            inc si
            cmp byte ptr ds:[si], 0
            jne interpret_loop
            ret

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
                ; if read 0Dh, read again to get only 0Ah
                je case_6

            eof_check:
                cmp ax, 0 ; if EOF - ax == 0
                jne break
                mov word ptr ds:[di], -1

            jmp break
        
        case_7:
            mov bp, si
            inc bp

            mov cl, 1
            for_loop:
                inc si
                brackets_switch:
                    cmp byte ptr ds:[si], '['
                    jne case_brackets_2
                    inc cl
                    jmp brackets_break

                    case_brackets_2:
                    cmp byte ptr ds:[si], ']'
                    jne brackets_break
                    dec cl

                    brackets_break:
                        cmp cl, 0
                        jne for_loop

            mov byte ptr ds:[si], 0

            while_loop:
                cmp word ptr ds:[di], 0
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
            jmp break
            
interpret endp

end start