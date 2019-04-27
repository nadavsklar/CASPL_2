; first commit
; second commit
section	.rodata			; we define (global) read-only variables in .rodata section
	elementLength: DD 5
	format_string: db "%s", 0
    format_int: db "%d", 10, 0
    format_char: db "%c", 10, 0
    format_hexa: db "%0x", 0
	calc_msg: dw "calc:"
	space_msg: dw 10
	const16: DD 16
	const256: DD 256

section .data           ; we define (global) initialized variables in .data section
	bufferLength: DD 80
	numOfActions: DD 88
	numValue: DD 0
	OP1: DD 0
	OP2: DD 0
	moduluValue: DD 0
	powerCounterBy16: DD 0
	powerCounterBy256: DD 0
    counterToInsert: DD 0
    isFirst: DD 1
	stackPointer: DD stack 					;;stack pointer


section .bss			; we define (global) uninitialized variables in .bss section
	buffer: resb 80 					;; store input buffer
	head: resb 5         			;; This is a pointer for a linked list
	tmp: resb 5 					;; This is a tmp pointer to the current link
	savehead: resb 5
	stack: resb 5 	;;stack address

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

		push calc_msg
		push format_string
		call printf
		add esp, 8

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

doNumber:			                                	; function that gets the value of the number the user entered and push it
	mov edi, 0
	startRight: 		                                ; starting moving from str[0] to str[size - 1]
		cmp byte [buffer + edi], 0
		je startLeft
		inc edi
		jmp startRight
	startLeft:			                                ; starting moving left from str[0]
		dec edi
		dec edi
		mov dword [numValue], 0			                ; sum = 0
        mov dword [counterToInsert], 0
		startLeftLoop:
			mov ecx, 0
			cmp edi, -1
			je endGetValue
			mov cl, byte [buffer + edi]
			cmp cl, 58			                        ; figuring if str[i] is letter or digit
			ja itsALetter 
			itsADigit:									; its a digit
				sub cl, '0'
				jmp endDigitOrLetter
			itsALetter:									; its a letter
				add cl, 10
				sub cl, 'A'
			endDigitOrLetter:							; ecx = the digit value, powerCounterBy16 = power
                inc dword [counterToInsert]             ; first digit or second from every couple
                cmp dword [counterToInsert], 2                ; if second
                je getNode                              ; jump
                getFirstDigitFrom2:                     ; else
					add dword [numValue], ecx               ; first digit - so taking it as it
					jmp endGetDigitFrom2
                
                getNode:
					mov eax, ecx                                ; eax = digit
					mul dword [const16]                         ; eax = digit * 16
					add dword [numValue], eax                   ; second digit - so we take it as digit * 16

					cmp dword [isFirst], 1                      ; is first?
					jne callPushNumber                          ; if not, just push number
					call pushFirstNode                          ; if first, push first node
					dec dword [isFirst]                         ; not first anymore
					jmp endPushNumber                           ; end push current node


					callPushNumber:                             ; pushes not first node
						call pushNumber

					endPushNumber:                              ; end push current node
						mov dword [numValue], 0                     ; current num value = 0
						mov dword [counterToInsert], 0				; counterToInsert = 0

                endGetDigitFrom2:                           ; moving forward
					dec edi
					jmp startLeftLoop
	endGetValue:
        cmp dword [numValue], 0                             ; is there are more digits we havent entered?
        je endDoNumber  
        call pushNumber                                     ; yes - push them
        endDoNumber:                                        ; else
		mov dword [head + 1], 0                             ; end of list = null
		add dword [stackPointer], 4                            ; stackPointer++
		mov dword [isFirst], 1
	    ret


plus:
	ret


popAndPrint:
	sub dword [stackPointer], 4								; getting the last address
	mov dword eax, [stackPointer]							; ebx = stackPointer
	mov dword ebx, [eax]
	mov edi, 0
	cleanBuffer:
        cmp edi, 80
        je moveRight
        mov byte [buffer + edi], 0
        inc edi
        jmp cleanBuffer
	moveRight:
		dec edi													; edi--
		cmp dword ebx, 0										; if *stackPointer == NULL
		je endMovRight
		mov eax, 0
		mov byte al, [ebx]
		mov byte [buffer + edi], al 							; buffer[edi] = al
		cmp byte al, 16											; buffer[edi] = 16?
		jb below16
		jmp endInsertingToBuffer
		below16:
			dec edi
			mov byte [buffer + edi], 0							; if al < 16, add leading zero
		endInsertingToBuffer:
		mov eax, [ebx + 1]										; eax = head->next
		mov [tmp], eax											; tmp = head->next
		mov dword [savehead], ebx
		push ebx												; free(head)
		call free
		add esp, 4
		mov dword ebx, [savehead]								; head = NULL
		mov dword [ebx], 0
		mov ebx, [tmp] 											; ebx = head->next
		jmp moveRight
	endMovRight:
		inc edi
		cmp edi, 80
		je endPrintNumber
		mov byte al, [buffer + edi]
		push eax
		push format_hexa
		call printf
		add esp, 8
		jmp endMovRight
	endPrintNumber:
		push space_msg
		push format_string
		call printf
		add esp, 8
		ret

duplicate:

	ret

pPower:
	ret

nPower:
	ret

nBits:
	ret

pushFirstNode:
    pushInit:
		push dword [elementLength]
		call malloc
		mov dword [head], eax					; head = malloc(elementLength)
		add esp, 4
		mov edx, dword [stackPointer]			; edx = stackPointer
		mov [edx], eax							; stack[stackPointer] = head;
		mov dword ebx, [head]					; ebx = head
        mov dword edx, [numValue]               ; edx = data
		mov byte [ebx], dl 						; head->data = edx
    ret

pushNumber:
	pushLoop:
		push dword [elementLength]
		call malloc	
		add esp, 4
		mov dword [tmp], eax					; tmp = malloc(elementLength)
		mov dword ebx, [head]					; ebx = head
		mov dword edx, [tmp]					; edx = temp
		mov dword [ebx + 1], edx				; head->next = tmp
        mov dword edx, [numValue]               ; edx = data
		mov dword ebx, [tmp] 		
		mov byte [ebx], dl						; tmp.data = edx
		mov dword ecx, [tmp]					; head = temp
		mov dword [head], ecx					; head = temp
	ret