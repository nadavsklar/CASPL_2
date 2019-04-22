; first commit
; second commit
section	.rodata			; we define (global) read-only variables in .rodata section
	elementLength: DD 5
	format_string: db "%s", 10, 0
    format_int: db "%d", 10, 0
    format_char: db "%c", 10, 0
    format_hexa: db "%x", 10, 0
	const16: DD 16
	const256: DD 256

section .data           ; we define (global) initialized variables in .data section
	bufferLength: DD 80
	stackLength: EQU 5 					;;stack size
	stack TIMES stackLength DD 0 		;;stack address
	stackPointer: DD 0 					;;stack pointer
	numOfActions: DD 88
	numValue: DD 0
	powerCounterBy16: DD 0
	struc link
		.data resb 1
		.next resb 4
	end struc

section .bss			; we define (global) uninitialized variables in .bss section
	buffer: resb 80 					;; store input buffer
	head: resb 1         			;; This is a pointer for a linked list
	tmp: resb 1 					;; This is a tmp pointer to the current link

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
		mov edi, 0
		CLEAN:
            cmp edi, 80
            je END_CLEAN
            mov byte [buffer + edi], 0
            inc edi
            jmp CLEAN
        END_CLEAN:
			push dword [stdin]
			push bufferLength
			push buffer
			call fgets
			add esp, 12

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
				jmp exit

		
	exit:
		popad			
		mov esp, ebp	
		pop ebp
		ret

doNumber:				; function that gets the value of the number the user entered
	mov edi, 0
	startRight: 		; starting moving from str[0] to str[size - 1]
		cmp byte [buffer + edi], 0
		je startLeft
		inc edi
		jmp startRight
	startLeft:			; starting moving left from str[0]
		dec edi
		dec edi
		mov dword [numValue], 0			; sum = 0
		mov dword [powerCounterBy16], 0						; power = 0
		startLeftLoop:
			mov ecx, 0
			cmp edi, -1
			je endGetValue
			mov cl, byte [buffer + edi]
			cmp cl, 58			; figuring if str[i] is letter or digit
			ja itsALetter 
			itsADigit:									; its a digit
				sub cl, '0'
				jmp endDigitOrLetter
			itsALetter:									; its a letter
				add cl, 10
				sub cl, 'A'
			endDigitOrLetter:							; ecx = the digit value, powerCounterBy16 = power
				call powerBy16							; return as eax 16^power
				mul ecx									; eax (16^power) = eax * ecx (digit)
				add dword [numValue], eax
				inc dword [powerCounterBy16]
				dec edi
				jmp startLeftLoop
	endGetValue:
		call pushNumber
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

powerBy16:						; powerCounterBy16 = power
	mov eax, 1					; sum = 1
	mov ebx, 0					; i = 0
	startPowerBy16Loop:
		cmp ebx, dword [powerCounterBy16]
		je endPowerBy16Loop
		mul dword [const16]					; sum = sum * 16
		inc ebx
		jmp startPowerBy16Loop
	endPowerBy16Loop:
		ret

pushNumber:
	mov eax, dword [numValue] 					; eax = the numeric value
	pushInit:
		cmp eax, 0 
		je endPushLoop
		div dword [const256]					; eax = eax / 256, edx = eax % 256
		mov ecx, eax							; ecx = eax
		push dword [elementLength]
		call malloc
		mov dword [head], eax					; head = malloc(elementLength)
		add esp, 4
		mov byte [head + data], edx 			; head.data = edx
		mov ebx, dword [head]
		mov dword [stack+stackPointer], ebx 	; stack[stackPointer] = head
		mov eax, ecx
	pushLoop:
		cmp eax, 0
		je endPushLoop
		div dword [const256]					; eax = eax / 256, edx = eax % 256
		mov ecx, eax							; ecx = eax
		push dword [elementLength]
		call malloc
		mov dword [tmp], eax					; tmp = malloc(elementLength)
		add esp, 4
		mov byte [tmp + data], edx 				; tmp.data = edx
		mov ebx, dword [tmp]
		mov dword [head + next], ebx			; head.next = tmp
		mov dword [head], ebx					; head = tmp
		mov eax, ecx
		jmp pushLoop
	endPushLoop:
		inc dword [stackPointer]
		ret