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

            case_1:
            cmp al, '<'
            jne case_2
            dec di
            dec di

            case_2:
            cmp al, '>'
            jne case_3
            inc di
            inc di

            case_3:
            cmp al, '+'
            jne case_4
            inc word ptr ds:[di]

            case_4:
            cmp al, '-'
            jne case_5
            dec word ptr ds:[di]

            case_5:
            cmp al, '.'
            jne case_6
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
            cmp al, ','
            jne case_7
            read_again:
            mov ah, 3fh ; syscall read file
            mov bx, 0 ; from stdin
            mov cx, 1 ; number of bytes to read/write
            mov dx, di ; to current pointer
            int 21h
            mov byte ptr ds:[di + 1], 0
            
            enter_check:
                cmp word ptr ds:[di], 0Dh
                ; if read 0Dh, read again to get only 0Ah
                je read_again

            eof_check:
                test ax, ax ; if EOF - ax == 0
                jnz break
                mov word ptr ds:[di], -1
            jmp break

            case_7:
            cmp al, '['
            jne break
            mov bp, si ; loop_begin
            inc bp

            mov cx, 1
            for_loop:
                inc si
                brackets_switch:
                    mov al, byte ptr ds:[si]
                    cmp al, '['
                    jne case_brackets_2
                    inc cx

                    case_brackets_2:
                    cmp al, ']'
                    jne brackets_break
                    dec cx

                    brackets_break:
                        test cx, cx
                        jnz for_loop

            mov byte ptr ds:[si], cl

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

        break:
            inc si
            cmp byte ptr ds:[si], 0
            je skip
            jmp interpret_loop
            skip:
            ret
            
interpret endp

end start