; first commit
; second commit
section	.rodata			; we define (global) read-only variables in .rodata section
	elementLength: DD 5

section .data           ; we define (global) initialized variables in .data section
	bufferLength: DD 80
	stackLength: EQU 5 					;;stack size
	stack TIMES stackLength DD 0 		;;stack address
	stackPointer: DD 0 					;;stack pointer
	quit: db 'q'
	plus: db '+'
	popAndPrint: db 'p'
	duplicate: db 'd'
	pPower: db '^'
	nPower: db 'v'
	numOfBits: db 'n'
	numOfActions: DD 0
	stdin: DD 0



section .bss			; we define (global) uninitialized variables in .bss section
	buffer: resb 80 					;; store input buffer

section .text
align 16
	global main
	extern printf
	extern fflush
	extern malloc
	extern calloc
	extern free
	extern fgets

main:
	pop    dword ecx    ; ecx = argc
    mov    esi,esp      ; esi = argv

    mov     eax,ecx     ; put the number of arguments into eax
    shl     eax,2       ; compute the size of argv in bytes
    add     eax,esi     ; add the size to the address of argv 
    add     eax,4       ; skip NULL at the end of argv
    push    dword eax   ; char *envp[]
    push    dword esi   ; char* argv[]
    push    dword ecx   ; int argc

    call    myCalc        ; int main( int argc, char *argv[], char *envp[] )

    mov     ebx,eax
    mov     eax,1
    int     0x80
    nop
	

myCalc:
	push ebp
	mov ebp, esp	
	pushad		

	doWhile:
		push dword [stdin]
		push bufferLength
		push buffer
		call fgets

		cmp byte [buffer], '+'
		je callPlus
		
		cmp byte [buffer], 'p'
		je callPopAndPrint

		cmp byte [buffer], 'd'
		je callDuplicate

		cmp byte [buffer], '^'
		je callPPower

		cmp byte [buffer], 'v'
		je callNPower

		cmp byte [buffer], 'n'
		je callBits

		cmp byte [buffer], 'q'
		je callExit

		callNumber:
			call doNumber
			jmp doWhile
			
		callPlus:
			call plus
			jmp doWhile

		callPopAndPrint:
			call popAndPrint
			jmp doWhile

		callDuplicate:
			call duplicate
			jmp doWhile

		callPPower:
			call pPower
			jmp doWhile
		
		callNPower:
			call nPower
			jmp doWhile

		callBits:
			call call nBits
			jmp doWhile

		callExit:

    popad			
    mov esp, ebp	
    pop ebp
    ret