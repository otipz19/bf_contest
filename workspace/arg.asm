.model tiny

.code
main proc
	mov ah, 09h	; write string to STDOUT
	mov dx, 82h	; get command line
	int 21h		; show it... ;-)
	mov ah, 4ch
    int 21h
main endp
end main