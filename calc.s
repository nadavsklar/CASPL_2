; first commit
section	.rodata			; we define (global) read-only variables in .rodata section

section .bss			; we define (global) uninitialized variables in .bss section

section .text
	extern printf

myCalc:
	push ebp
	mov ebp, esp	
	pushad		

	mov ecx, dword [ebp+8]	; get function argument (pointer to string)

	; your code comes here...

    
    add esp, 8		; clean up stack after call

    popad			
    mov esp, ebp	
    pop ebp
    ret