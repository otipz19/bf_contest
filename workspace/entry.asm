.model tiny
 
.data
    code_buffer_size equ 10001
    data_buffer_size equ 20000
    code_buffer_offset equ 30000
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

set_DTA:
    mov ah, 1ah
    mov dx, si ; code buffer
    int 21h

open_file:
    mov ah, 0fh ; open file via FCB
    mov dx, 5ch ; unopened FCB of first command line argument
    int 21h

read_file:
    ;mov ah, 14h ; sequantial read via FCB
    ;mov byte ptr ds:[7ch], 0 ; address of CurRec
    mov ah, 27h ; random read via FCB
    mov cl, 125 ; read 125 sectors of 80 bytes
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
                mov ah, 02h ; write char in dl to stdout
                cmp byte ptr ds:[di], 0Ah
                jne write_char
                ; write also 0Dh to stdout
                mov dl, 0Dh
                int 21h
            write_char:
                mov dl, byte ptr ds:[di] ; by current pointer
                int 21h
                jmp break

        case_6:
            mov ah, 3fh ; syscall read file
            mov bx, 0 ; from stdin
            mov cx, 1 ; number of bytes to read/write
            mov dx, di ; to current pointer
            int 21h
            
            enter_check:
                cmp word ptr ds:[di], 0Dh
                ; if read 0Dh, read again to get only 0Ah
                je case_6

            eof_check:
                test ax, ax ; if EOF - ax == 0
                jnz break
                mov word ptr ds:[di], -1

            jmp break
        
        case_7:
            mov bp, si ; loop_begin
            inc bp

            mov al, 1
            for_loop:
                inc si
                brackets_switch:
                    cmp byte ptr ds:[si], '['
                    jne case_brackets_2
                    inc al

                    case_brackets_2:
                    cmp byte ptr ds:[si], ']'
                    jne brackets_break
                    dec al

                    brackets_break:
                        test al, al
                        jnz for_loop

            mov byte ptr ds:[si], al

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