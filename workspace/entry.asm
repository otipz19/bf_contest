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
    mov ch, 75h ; with cl == ffh initially, cx == 75ffh
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
    mov ah, 27h ; random read via FCB
    mov ch, ah ; read 255 sectors of 80 bytes
    int 21h

interpret:
    mov al, byte ptr ds:[si]
        
    case_7:
        cmp al, '['
        je loop_interpret
        
    case_8:
        cmp al, ']'
        je restore_code_pointer

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
        jne case_6
        inc word ptr ds:[di]

    case_6:
        cmp al, ','
        jne case_4

        read_again:
            mov ah, 3fh ; syscall read file
            mov cx, 1 ; number of bytes to read/write
            mov dx, di ; to current pointer
            int 21h
            mov byte ptr ds:[di + 1], bl
            
        enter_check:
            cmp word ptr ds:[di], 0Dh
            ; if read 0Dh, read again to get only 0Ah
            je read_again

        eof_check:
            test ax, ax ; if EOF - ax == 0
            jnz break
            mov word ptr ds:[di], -1

    case_4:
        cmp al, '-'
        jne case_5
        dec word ptr ds:[di]

    case_5:
        cmp al, '.'
        jne break

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

    break:
        inc si
        cmp byte ptr ds:[si], bl
        jne interpret
        ret

    restore_code_pointer:
        pop si

    loop_interpret:
        push si ; save code_pointer
        
        while_loop:
            cmp word ptr ds:[di], bx 
            jne break

        mov cx, 1

        for_loop:
            inc si

            brackets_switch:
                mov al, byte ptr ds:[si]

                case_brackets_1:
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
                    pop bp
                    jmp break

            
end start