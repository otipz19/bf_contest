.model tiny
.stack 100h

.data
buffer db 50 dup(?)         ; Buffer to store the input string
substring db 50 dup(?)      ; Buffer to store the substring
msg db 13,10,'Enter a string: $'
newline db 13,10,'$'

.code
main proc
    mov ax, @data
    mov ds, ax
    
    ; Get the memory address of the string
    mov si, offset buffer
    
    ; Read string from input
    mov ah, 0Ah
    mov dx, 82h      ; Pass the memory address to DX
    int 21h
    
    ; Find the first space in the string
    mov di, offset substring  ; Destination index for substring
    mov cx, 50               ; Maximum characters to copy
search_loop:
    mov al, [si]     ; Load the character at SI
    cmp al, ' '      ; Check if it's a space
    je found_space   ; If yes, jump to found_space
    mov [di], al     ; Copy character to substring buffer
    inc si           ; Move to the next character in input string
    inc di           ; Move to the next character in substring buffer
    loop search_loop ; Continue searching
    jmp end_program  ; If no space found, end the program

found_space:
    mov byte ptr [di], '$'  ; Terminate the substring with '$'

    ; Print the substring
    mov ah, 09h
    lea dx, substring
    int 21h
    ; Print new line
    lea dx, newline
    int 21h

end_program:
    mov ah, 4Ch       ; DOS exit function
    int 21h
main endp
end main
