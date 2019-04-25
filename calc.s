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
	stack: dd 0, 0, 0, 0, 0		;;stack address
	stackPointer: DD 0 					;;stack pointer
	numOfActions: DD 88
	numValue: DD 0
	moduluValue: DD 0
	powerCounterBy16: DD 0
	powerCounterBy256: DD 0
	struc link
		data resb 1
		next resb 4
	endstruc

section .bss			; we define (global) uninitialized variables in .bss section
	buffer: resb 80 					;; store input buffer
	head: resb 1         			;; This is a pointer for a linked list
	tmp: resb 1 					;; This is a tmp pointer to the current link
	savehead: resb 1

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

powerBy256:						; powerCounterBy256 = power
	mov eax, 1					; sum = 1
	mov ebx, 0					; i = 0
	startPowerBy256Loop:
		cmp ebx, dword [powerCounterBy256]
		je endPowerBy256Loop
		mul dword [const256]					; sum = sum * 256
		inc ebx
		jmp startPowerBy256Loop
	endPowerBy256Loop:
		ret

pushNumber:
	mov eax, dword [numValue] 					; eax = the numeric value
	pushInit:
		cmp eax, 0 
		je endPushLoop
		div dword [const256]					; eax = eax / 256, edx = eax % 256
		push dword [elementLength]
		mov dword [numValue], eax
		mov dword [moduluValue], edx
		call malloc
		mov dword [head], eax					; head = malloc(elementLength)
		add esp, 4
		mov edx, dword [stackPointer]			; edx = stackPointer
		mov [stack + edx], eax					; stack[stackPointer] = eax (head)
		mov dword eax, [numValue]				; returning eax to numValue after malloc
		mov dword edx, [moduluValue]			; returning edx to moduluValue after malloc
		mov dword ebx, [head]					; ebx = head
		mov byte [ebx], dl 						; head->data = edx
	pushLoop:
		cmp eax, 0
		je endPushLoop
		div dword [const256]					; eax = eax / 256, edx = eax % 256
		cmp edx, 0
		je endPushLoop
		push dword [elementLength]
		mov dword [numValue], eax				; numValue = eax
		mov dword [moduluValue], edx			; moduluValue = edx
		call malloc	
		mov dword ebx, [head]					; saving head
		push ebx								; saving head
		mov dword [tmp], eax					; tmp = malloc(elementLength), from some reason head is driven here, so we did push
		pop ebx
		mov dword [head], ebx					; resolving head
		add esp, 4
		mov dword ebx, [head]					; ebx = head
		mov dword edx, [tmp]					; edx = temp
		mov dword [ebx + 1], edx				; head->next = tmp
		mov dword eax, [numValue]				; returning eax to numValue
		mov dword edx, [moduluValue]			; returning edx to moduluValue
		mov dword ebx, [tmp] 		
		mov byte [ebx], dl						; tmp.data = edx
		mov dword ecx, [tmp]					; head = temp
		mov dword [head], ecx					; head = temp;
		cmp edx, 0
		je endPushLoop
		jmp pushLoop
	endPushLoop:
		mov dword [head + 1], 0
		inc dword [stackPointer]
		call popNumber
		ret

popNumber:
	dec dword [stackPointer]
	mov dword [numValue], 0						; numValue = 0
	mov edx, dword [stackPointer]				; edx = stackPointer
	mov ebx, dword [stack + edx]				; ebx = stack[stackPointer]
	mov dword [head], ebx						; head = stack[stackPointer]
	mov dword [powerCounterBy256], 0
	popLoop:
		sas:
		mov ecx, 0
		mov ebx, dword [head]						; ebx = head 
		mov byte cl, [ebx]						; ecx = head->data
		ssss:
		call powerBy256								; eax = 256^i
		mul ecx										; eax = eax * ecx (256^i * head->data)
		add dword [numValue], eax					; numValue += eax
		bb:
		mov dword ebx, [head]
		cmp dword [ebx + 1], 0						; if (head->next == null)
		bb1:
		je endPopNumber								; end
		bb2:
		push dword [head]							; push head
		mov ecx, dword [ebx + 1]
		mov dword [head], ecx						; head = head->next				
		bb3:
		call free									; free(head)
		add esp, 4
		bb4:
		inc dword [powerCounterBy256]
		jmp popLoop
	endPopNumber:
		push dword [head]
		call free
		add esp, 4
		mov eax, dword [numValue]
	ret