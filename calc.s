; first commit
; second commit
section	.rodata			; we define (global) read-only variables in .rodata section
	elementLength: DD 5
	format_string: db "%s", 0
    format_int: db "%d", 10, 0
    format_char: db "%c", 10, 0
    format_hexa: db "%0X", 0
	binaryBits: DD 0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4
	calc_msg: dw "calc:"
	space_msg: dw 10
	const16: DD 16
	const256: DD 256

section .data           ; we define (global) initialized variables in .data section
	bufferLength: DD 80
	numOfActions: DD 88
	numValue: DD 0
	moduluValue: DD 0
	powerCounterBy16: DD 0
	powerCounterBy256: DD 0
    counterToInsert: DD 0
    isFirst: DD 1
	stackPointer: DD stack 					;;stack pointer
	stackPointerTmp1: DD stack
	stackPointerTmp2: DD stack
	carry: db 0
	carry1: db 0
	carry2: db 0
	totalBits: DD 0
	powerValue: db 0
	printFlag: DD 1
	tempEDI: DD 0
	

section .bss			; we define (global) uninitialized variables in .bss section
	buffer: resb 80 					;; store input buffer
	coefficient: resb 10000				;; store the coefficient buffer
	OP1: resb 80						;; op1 of the plus action
	OP2: resb 80						;; op2 of the plus action
	head: resb 5         			;; This is a pointer for a linked list
	tmp: resb 5 					;; This is a tmp pointer to the current link
	savehead: resb 5
	stack: resb 5 					;;stack address
	hugeBuffer: resb 100000


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
		cmp dword [isFirst], 1
		je insertOneDigitOnly  
        call pushNumber                                     ; yes - push them
		jmp endDoNumber
		insertOneDigitOnly:
			call pushFirstNode
        endDoNumber:                                        ; else
		mov dword [head + 1], 0                             ; end of list = null
		add dword [stackPointer], 4                            ; stackPointer++
		mov dword [isFirst], 1
	    ret


plus:
	sub dword [stackPointer], 4								; getting the last address
	mov dword eax, [stackPointer]							; ebx = stackPointer
	mov dword ebx, [eax]
	mov edi, 0
	cleanOp1:
        cmp edi, 80
        je moveRightOP1
        mov byte [OP1 + edi], 0
        inc edi
        jmp cleanOp1

	moveRightOP1:
		dec edi													; edi--
		cmp dword ebx, 0										; if *stackPointer == NULL
		je startOP2
		mov eax, 0
		mov byte al, [ebx]
		mov byte [OP1 + edi], al 							; buffer[edi] = al
		mov eax, [ebx + 1]										; eax = head->next
		mov [tmp], eax											; tmp = head->next
		mov dword [savehead], ebx
		push ebx												; free(head)
		call free
		add esp, 4
		mov dword ebx, [savehead]								; head = NULL
		mov dword [ebx], 0
		mov dword [ebx + 1], 0
		mov ebx, [tmp] 											; ebx = head->next
		jmp moveRightOP1

	startOP2:
		sub dword [stackPointer], 4								; getting the last address
		mov dword eax, [stackPointer]							; ebx = stackPointer
		mov dword ebx, [eax]
		mov edi, 0

	cleanOp2:
		cmp edi, 80
        je moveRightOP2
        mov byte [OP2 + edi], 0
        inc edi
        jmp cleanOp2

	moveRightOP2:
		dec edi													; edi--
		cmp dword ebx, 0										; if *stackPointer == NULL
		je beforeAdding
		mov eax, 0
		mov byte al, [ebx]
		mov byte [OP2 + edi], al 							; buffer[edi] = al
		mov eax, [ebx + 1]										; eax = head->next
		mov [tmp], eax											; tmp = head->next
		mov dword [savehead], ebx
		push ebx												; free(head)
		call free
		add esp, 4
		mov dword ebx, [savehead]								; head = NULL
		mov dword [ebx], 0
		mov dword [ebx + 1], 0
		mov ebx, [tmp] 											; ebx = head->next
		jmp moveRightOP2
	
		beforeAdding:
		mov dword [isFirst], 1
		mov edi, 79
			startAdding:
				mov byte [carry1], 0 
				mov byte [carry2], 0
				cmp byte [OP1 + edi], 0
				jne mustAdd
				cmp byte [OP2 + edi], 0
				jne mustAdd
				doneAdding:
					cmp dword [carry], 0
					je endPlus
					mov dword ecx, [carry]
					mov dword [numValue], ecx
					call pushNumber
					jmp endPlus
				mustAdd:
					mov ecx, 0
					mov byte cl, [OP1 + edi]
					add byte cl, [OP2 + edi]
					jnc NotFirstCarry
					firstCarry:
						mov byte [numValue], cl
						mov byte [carry1], 1
					NotFirstCarry:
						add byte cl, [carry]
						jnc NotSecondCarry
						secondCarry:
							mov byte [carry2], 1
						NotSecondCarry:
							mov byte [numValue], cl
							mov dword edx, 0
							mov byte dl, [carry1]
							add byte dl, [carry2]
							mov byte [carry], dl
					
					endMoveCarry:
					cmp dword [isFirst], 1                      ; is first?
					jne callPushNumberPlus                        ; if not, just push number
					call pushFirstNode                          ; if first, push first node
					dec dword [isFirst]                         ; not first anymore
					jmp endPushNumberPlus                           ; end push current node


					callPushNumberPlus:                             ; pushes not first node
						call pushNumber

					endPushNumberPlus:
						dec edi
						jmp startAdding
		endPlus:
		mov byte [carry], 0
		mov byte [carry1], 0
		mov byte [carry2], 0
		mov dword [isFirst], 1
		mov dword [head + 1], 0                             ; end of list = null
		add dword [stackPointer], 4                            ; stackPointer++
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
			cmp dword [ebx + 1], 0								; last digit?
			je endInsertingToBuffer
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
		mov dword [ebx + 1], 0
		mov ebx, [tmp] 											; ebx = head->next
		jmp moveRight
	endMovRight:
		inc edi
		cmp edi, 80
		je endPrintNumber
		mov byte al, [buffer + edi]
		cmp dword [printFlag], 0
		je dontPrintAtAll
		push eax
		push format_hexa
		call printf
		add esp, 8
		jmp endMovRight
	endPrintNumber:
		cmp dword [printFlag], 0
		je dontPrintAtAll
		push space_msg
		push format_string
		call printf
		add esp, 8
	dontPrintAtAll:
		ret

duplicate:
	sub dword [stackPointer], 4								; getting the last address
	mov dword eax, [stackPointer]							; ebx = stackPointer
	mov dword ebx, [eax]
	add dword [stackPointer], 4
	mov dword [isFirst], 1
	moveRightDuplicate:													
		mov dword [numValue], 0
		cmp dword ebx, 0										; if *stackPointer == NULL
		je endMovRightDuplicate
		mov eax, 0
		mov byte al, [ebx]
		mov byte [numValue], al 								; numValue = al
		mov dword [savehead], ebx
		cmp dword [isFirst], 1                     				; is first?
		jne callPushNumberDuplicate                    			; if not, just push number
		call pushFirstNode                          			; if first, push first node
		dec dword [isFirst]                         			; not first anymore
		jmp endPushNumberDuplicate                           	; end push current node
		
		callPushNumberDuplicate:
			call pushNumber
		
		endPushNumberDuplicate:
			mov dword ebx, [savehead]
			mov eax, [ebx + 1]										; eax = head->next
			mov [tmp], eax											; tmp = head->next								
			mov ebx, [tmp] 											; ebx = head->next
			jmp moveRightDuplicate

		endMovRightDuplicate:
			mov dword [isFirst], 1
			mov dword [head + 1], 0                             ; end of list = null
			add dword [stackPointer], 4
	ret

pPower:
	startPower:
		sub dword [stackPointer], 8								; getting the last address
		mov dword eax, [stackPointer]							; ebx = stackPointer
		mov dword ebx, [eax]
		add dword [stackPointer], 8

	calcPower:
		cmp dword ebx, 0									 	; if *stackPointer == NULL
		je preparePopCoefficient
		mov eax, 0
		mov byte al, [ebx]
		mov byte [powerValue],al

	preparePopCoefficient:
		sub dword [stackPointer], 4								; getting the last address
		mov dword eax, [stackPointer]							; ebx = stackPointer
		mov dword ebx, [eax]
		mov edi, 0

	cleanCoefficient:
        cmp edi, 10000
        je popCoefficient
        mov byte [coefficient + edi], 0
        inc edi
        jmp cleanCoefficient

	popCoefficient:
		dec edi													; edi--
		cmp dword ebx, 0										; if *stackPointer == NULL
		je popPower
		mov eax, 0
		mov byte al, [ebx]
		mov byte [coefficient + edi], al 							; buffer[edi] = al
		mov eax, [ebx + 1]										; eax = head->next
		mov [tmp], eax											; tmp = head->next
		mov dword [savehead], ebx
		push ebx												; free(head)
		call free
		add esp, 4
		mov dword ebx, [savehead]								; head = NULL
		mov dword [ebx], 0
		mov dword [ebx + 1], 0
		mov ebx, [tmp] 											; ebx = head->next
		jmp popCoefficient

	popPower:
		mov dword [tempEDI], edi
		dec dword [printFlag]
		call popAndPrint
		inc dword [printFlag]
		mov dword edi, [tempEDI]
		inc edi
	pushCoefficient:
		mov dword [isFirst], 1
		moveRightCoefficient:
			cmp byte [coefficient + edi], 0										; if *stackPointer == NULL
			je endMovRightCoefficient
			mov ecx, 0
			mov byte cl, [coefficient + edi]													
			mov byte [numValue], cl								; numValue = al
			cmp dword [isFirst], 1                     				; is first?
			jne callPushNumberCoefficient                    			; if not, just push number
			call pushFirstNode                          			; if first, push first node
			dec dword [isFirst]                         			; not first anymore
			jmp endPushNumberCoefficient                           	; end push current node
			
			callPushNumberCoefficient:
				call pushNumber
			
			endPushNumberCoefficient:
				dec edi								; ebx = head->next
				jmp moveRightCoefficient

			endMovRightCoefficient:
				mov dword [isFirst], 1
				mov dword [head + 1], 0                             ; end of list = null
				add dword [stackPointer], 4	

	calcResultOfPower:
		cmp byte [powerValue], 0
		je endpPower
		call duplicate
		call plus
		dec byte [powerValue]
		jmp calcResultOfPower

	 endpPower:

	ret

nPower:
	ret

nBits:
	sub dword [stackPointer], 4								; getting the last address
	mov dword eax, [stackPointer]							; ebx = stackPointer
	mov dword ebx, [eax]
	mov dword [totalBits], 0
	nBitsLoop:
		cmp dword ebx, 0										; if *stackPointer == NULL
		je endnBitsLoop
		mov eax, 0
		mov byte al, [ebx]
		mov ecx, [const16]
		mov edx, 0
		div ecx
		call countNumberOfOnesX
		call countNumberOfOnesY
		mov eax, [ebx + 1]										; eax = head->next
		mov [tmp], eax											; tmp = head->next
		mov dword [savehead], ebx
		push ebx												; free(head)
		call free
		add esp, 4
		mov dword ebx, [savehead]								; head = NULL
		mov dword [ebx], 0
		mov dword [ebx + 1], 0
		mov ebx, [tmp] 											; ebx = head->next
		jmp nBitsLoop
	endnBitsLoop:
		call pushNumberNbits
	ret

pushNumberNbits:
	mov dword [isFirst], 1
	mov dword eax, [stackPointer]							; ebx = stackPointer
	mov dword ebx, [eax]
	mov eax, [totalBits]
	loopNbitsPush:
	cmp eax, 0
	je endNbitsPush
	mov edx, 0
    mov ecx, [const256]
    div ecx
	mov dword [numValue], edx								; numValue = edx
	cmp dword [isFirst], 1                     				; is first?
	jne callPushNumberNbitsPush                   			; if not, just push number
	call pushFirstNode                          			; if first, push first node
	dec dword [isFirst]                         			; not first anymore
	jmp endPushNumberNbitsPush                           	; end push current node
		
	callPushNumberNbitsPush:
			call pushNumber
		
	endPushNumberNbitsPush:
		mov eax, [ebx + 1]										; eax = head->next
		mov [tmp], eax											; tmp = head->next								
		mov ebx, [tmp] 											; ebx = head->next
		jmp loopNbitsPush

	endNbitsPush:
		mov dword [isFirst], 1
		add dword [stackPointer], 4
	ret

countNumberOfOnesX:
	mov ecx, [binaryBits + edx*4]
	add [totalBits], ecx
	ret

countNumberOfOnesY:
	mov ecx, [binaryBits + eax*4]
	add [totalBits], ecx
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