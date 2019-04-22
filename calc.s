; first commit
; second commit
section	.rodata			; we define (global) read-only variables in .rodata section
	elementLength: DD 5
	format_string: db "%s", 10, 0
    format_int: db "%d", 10, 0
    format_char: db "%c", 10, 0
    format_hexa: db "%x", 10, 0

section .data           ; we define (global) initialized variables in .data section
	bufferLength: DD 80
	stackLength: EQU 5 					;;stack size
	stack TIMES stackLength DD 0 		;;stack address
	stackPointer: DD 0 					;;stack pointer
	numOfActions: DD 88



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
	extern stdin
	extern stdout
	extern stderr

main:
	mov eax, 7
	push eax
	push format_int
	call printf
    call myCalc        ; int main( int argc, char *argv[], char *envp[] )

    mov     ebx,0
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
			call nBits
			jmp doWhile

		callExit:

    popad			
    mov esp, ebp	
    pop ebp
    ret

doNumber:
	ret
plus:
	ret
popAndPrint:
	ret
duplicate:
	ret
pPower:
	ret
nPower:
	ret
nBits:
	ret
