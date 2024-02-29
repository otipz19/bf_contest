section .data
    error_file_nf db "file not found", 0
    buffer_size equ 10000
    err_length equ 15
    
section .bss
    buffer resb buffer_size
    file_descriptor resd 1
    
section .text
global main

main:
    pop eax ; pop args counter
    pop eax ; pop program name 

open_file:
    mov eax, 5 ; syscall open file
    pop ebx ; pop filename address from first console argument
    mov ecx, 0 ; open read-only
    int 0x80
    call check_error
    mov [file_descriptor], eax 
    
read_file:
    mov eax, 3 ; syscall read file
    mov ebx, [file_descriptor]
    mov ecx, buffer ; to read into buffer
    mov edx, buffer_size ; bytes to read
    int 0x80
    call check_error
    
write_stdout:
    mov edx, eax ; eax - successfully read bytes - to edx - how many bytes to write
    mov eax, 4 ; syscall write file
    mov ebx, 1 ; to stdout
    mov ecx, buffer ; from buffer
    int 0x80
    call check_error
    
exit:
    mov eax, 1
    mov ebx, 0
    int 0x80
    
check_error:
    test eax, eax
    jns no_error ; if error happened, eax is negative
    mov eax, 4 ; write
    mov ebx, 1 ; to stdout
    mov ecx, error_file_nf ; from error msg
    mov edx, err_length ; error msg length
    int 0x80
    call exit
    no_error:
        ret