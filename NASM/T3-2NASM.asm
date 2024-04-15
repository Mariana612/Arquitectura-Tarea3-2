; Creditos a Russ Ross por la base de la implementacion de ITOA. Link al video: https://www.youtube.com/watch?v=D7gabV6tWCE

global _start

section .data
	text1 db "Ingrese un numero", 0xA, 0 					
	digitos db '0123456789ABCDEF'     						;Caracteres que representan los dígitos en base 16
	errorCode db "ERROR: Ingrese un numero valido", 0xA, 0
	prompt_msg db "Desea cambiar los numeros? 1. Si | 2. No" , 0xA, 0
	itoaNum dq 0											;numero para procesar en itoa (resultados de suma y resta)
	itoaNumHigh dq 0
	itoaNumLow dq 0
	numBase dq 2											;numero utilizado para la base del itoa
	flagNegativo db 0										;flag que indica que el numero es negativo
	flagSpCase db 0											;flag del caso especial de la resta65
	flagHasError db 0
	flagIsInside db 0
	negSign db "-" 
	sumPrint db "Print de sumas:", 0xA, 0
	restPrint db "Print de restas:", 0xA, 0
	divPrint db "Print de division:", 0xA, 0
	overflowMsg db "ERROR: Overflow", 0xA, 0
	startPrompt db "Escoja una Opcion: 1. suma 2. resta 3. division 4. multiplicacion 5.Finalizar Programa",0xA,0
	printCont dq 0
	divisionError db "ERROR: Division por cero.", 0xA, 0          
	mulPrint db "Print de multiplicaciones:", 0xA, 0
	compare_num dq "18446744073709551615"					;indica el numero maximo a ingresar
	mul_strHigh db "0000000000000000000000000000000000000000000000000000000000000000", 0
	mul_strLow db  "0000000000000000000000000000000000000000000000000000000000000000", 10, 0
	espacio db 10
	

section .bss
	numString resq 13 
	num1 resq 13
	num2 resq 13
	length resb 1
	buffer resb 101   									;Buffer para almacenar la cadena de caracteres convertida

section .text

;------------------ MAIN ------------------------
_start:
	call _cleanRegisters	;Se utiliza cuando se ingresa un numero con error

	mov rax, startPrompt
	call _genericprint	;print inicial
	
	call _getOption

	;mov qword [numBase],2

	cmp byte[numString], '1'
	je _opSuma

	cmp byte[numString], '2'
	je _opResta

	cmp byte[numString], '3'
	je _opDivision

	cmp byte[numString], '4'
	je _opMultiplicacion

	cmp byte[numString], '5'
	je _finishCode

	call _finishError	;Se utiliza cuando se ingresa un numero con error
	jmp _start

	;------------------INICIO ------------------------

_cleanRegisters:
	mov rdi, length
	mov rcx, 101    ;Se puede tener max 21 caracteres
	mov al, 0      ;Se limpia con NULL bytes
	rep stosb      ;Se llena la memoria con NULL bytes

	mov rdi, numString
	mov rcx, 104    ;Se puede tener max 21 caracteres
	mov al, 0      ;Se limpia con NULL bytes
	rep stosb      ;Se llena la memoria con NULL bytes

	ret

	;------------------INICIO ------------------------
	
_opSuma:
	mov byte[flagHasError],0 	;Reinicia el flag de error
	mov byte[flagIsInside],1	;Establece que esta dentro de una funcion

	call _getUserInput
	cmp byte[flagHasError],1
	je _opSuma			;reinicia el loop
	

	call _sumaContinue
	cmp byte[flagHasError],1
	je _opSuma
	
_sumaContinue:
	;#SUMA
	mov rax, [num1]
    	add rax, [num2]			;Hace la suma
	jc _overflowDetected		;check de overflow



	mov [itoaNum], rax		;inicio itoa suma
	mov rax, sumPrint
	call _genericprint

	call _processLoop
	jmp _finishCode
	

_opResta:
	mov byte[flagHasError],0 	;Reinicia el flag de error
	mov byte[flagIsInside],1	;Establece que esta dentro de una funcion

	call _getUserInput
	cmp byte[flagHasError],1
	je _opResta

	;#RESTA
	mov rax, restPrint
	call _genericprint
	call _specialCaseSub		;realiza chequeo de casos especiales (numeros de len 20)

	mov rax, [num2]
	mov rsi, [num1]
	cmp rax, rsi	
	jg _resta ;Resta num2-num1
    	jle _cambio_resta ;Resta num1-num2

_restaEspecial:
	sub rax, rsi ;Resta num2-num1
	neg rax ;Negar resultado
	mov [itoaNum], rax ;inicio itoa resta
	jmp restaCont

_resta:
	;Si el número es mayor que cierto dígito, se debe negar el resultado
	mov r10, 9900000000000000000
	cmp rsi, r10
	jae _restaEspecial
    
	mov byte[flagNegativo], 1	;indica que el numero es negativo
	sub rax, rsi ;Resta num2-num1
	mov [itoaNum], rax ;inicio itoa resta

restaCont:
	call _processLoop
	mov byte[flagNegativo], 0
	jmp _finishCode
	call _processLoop
	call _finishCode

_cambio_restaEspecial:
	mov byte[flagNegativo], 1	;indica que el numero es negativo
	sub rsi, rax ;Resta num1-num2
	neg rsi ;Negar resultado
	mov [itoaNum], rsi ;inicio itoa resta               
	jmp restaCont

_cambio_resta:
	;Si el número es mayor que cierto dígito, se debe negar el resultado
	mov r10, 9900000000000000000
	cmp rax, r10
	jae _cambio_restaEspecial
	
	sub rsi, rax ;Resta num1-num2
	mov [itoaNum], rsi ;inicio itoa resta
	
	jmp restaCont ;Se imprime el resultado de la resta

_opDivision:
	mov byte[flagHasError],0 	;Reinicia el flag de error
	mov byte[flagIsInside],1	;Establece que esta dentro de una funcion

	call _getUserInput
	cmp byte[flagHasError],1
	je _opDivision
		
	;#DIVISIÓN
	mov rax, divPrint
	call _genericprint
	
	mov rax, [num1]
	mov rbx, [num2]
	cmp rax, rbx
	jge mayor_num1 ;Salto si num1 es mayor o igual a num2
	xchg eax, ebx
	
	mayor_num1:
		;Caso para la division por cero 
		cmp rbx, 0
		je division_by_zero
			
		;resultado se guarda en rax (cociente)
		xor rdx, rdx
		div rbx
			
		mov [itoaNum], rax
		call _processLoop

	jmp _finishCode

division_by_zero:
	mov rax, divisionError
	call _genericprint
	jmp _opDivision
	
_opMultiplicacion:
	mov byte[flagHasError],0 	;Reinicia el flag de error
	mov byte[flagIsInside],1	;Establece que esta dentro de una funcion

	call _getUserInput
	cmp byte[flagHasError],1
	je _opMultiplicacion
	
	;#MULTIPLICACIÓN
	mov rax, mulPrint
	call _genericprint
	call _specialCaseSub		;realiza chequeo de casos especiales (numeros de len 20)
	
	mov rax, [num1]
	mov rsi, [num2]
    mul rsi			;Hace la multiplicación
    jc mulEspecial
    mov [itoaNum], rax		;inicio itoa multiplicación
	call _processLoop
	
	jmp _finishCode
	
	mulEspecial:
		push rax
		mov [itoaNumHigh], rdx		;inicio itoa multiplicación
		mov rdi, mul_strHigh
		mov rsi, [itoaNumHigh]
		call _startItoa_Mul
	
		mov rax, mul_strHigh
		call _genericprint
    
		pop rax
		mov [itoaNumLow], rax		;inicio itoa multiplicación
		mov rdi, mul_strLow
		mov rsi, [itoaNumLow]
		call _startItoa_Mul
	
		mov rax, mul_strLow
		call _genericprint
	
	_processLoop_mul:
		cmp qword [numBase], 16
		jg finish

	_continueLoop_mul:
		mov rdi, buffer
		mov rcx, 44    ;Se puede tener max 21 caracteres
		mov al, 0      ;Se limpia con NULL bytes
		rep stosb      ;Se llena la memoria con NULL bytes
    
		mov rdi, buffer
		call _startItoa_Mul
	
		inc qword [numBase]
		jmp _processLoop_mul

	finish:	
		jmp _finishCode

_getUserInput:	
	
	mov rax, text1
	call _genericprint
	call _getText			;Consigue el texto del usuario
	cmp byte[flagHasError],1
	je _exitFunction


	mov byte[numString], 0		;reinicia numString
	mov qword [num1], rax		;carga el primer numero en num1
	xor rax, rax			;reinicia rax
	mov byte[numString], 0		;reinicia numString
	
	mov rax, text1   		;Hace print inicial
	call _genericprint
	
	call _getText			;Consigue el texto del usuario
	mov qword [num2], rax		;carga el primer numero en num2
	cmp byte[flagHasError],1
	je _exitFunction

	ret
;------------------ATOI---------------------------------------
_AtoiStart:
	xor rbx, rbx			;reinicia el registro
	xor rax, rax			;reinicia el registro
	lea rcx, [numString]			;ingresa el numString a rcx
	jmp _Atoi

_Atoi:
	mov bl, byte[rcx]
	cmp bl, 0xA		
	je _exitFunction		;se asegura de que sea el final del string

	sub rbx,30h			;resta 30h al string para volverlo el numero
	imul rax, 10 			;multiplica el numero almacenado en rax x 10 para volverlo decimal
	add rax, rbx			;agrega el ultimo numero obtenido a rax (ej: 10+3=13)
	jc _overflowDetected		;check de overflow


	xor rbx,rbx			;reinicia el registro
	inc rcx				;incrementa x 1 el rcx (obtiene el siguiente caracter
	jmp _Atoi			;realiza loop

_exitFunction: 
	ret
;----------------- END ATOI ---------------------------------

;----------------- CHEQUEO DE ERRORES -----------------------

;---#chequea que el caracter ingresado sea un int
_inputCheck:  			
				
	mov rsi, numString					;direccion del buffer de ingreso
    	xor rcx, rcx					;Clear counter

	check_input:

		movzx rax, byte [rsi + rcx]		;Carga el byte actual
        	cmp rax, 0xA
        	je input_valid				;Final del string alcanzado
        	cmp rax, '0'
        	jb input_invalid				;Revisa caracteres no imprimibles
        	cmp rax, '9'
        	ja input_invalid				;Revisa caracteres no imprimibles
        	inc rcx					;Mover al siguente byte
        	jmp check_input

	input_valid:
		ret


input_invalid:
	call _cleanRegisters
	mov rax, prompt_msg
	call _genericprint
	
	call _getOption
    cmp byte [numString], '1'   ; Si elige 1, continuar cambiando números
    je _finishErrorInput
    cmp byte [numString], '2'   ; Si elige 2, finalizar el programa
    je _finishCode
    
    
    
    jmp input_invalid           ; Si la entrada no es válida, repetir el proceso
	
	

;---#SPECIAL CASE
;handling de errores que causa que la funcion no pueda manejar numeros de 20 de largo, 
;al contar el primer 1 como un numero negativo

_specialCaseSub: 

	mov rax, [num1]
	call _countInt					;calcula lngitud de numero2
	;---------------

	cmp byte [length], 20				;compara que el tamano es 20
	je _num20
	
	mov rax, [num2]
	call _countInt

	cmp byte [length], 20
	jne _exitFunction				;si ambos son menores a 20, no es caso especial
	mov byte [flagSpCase], 1			;caso especial
	ret

	;CALL _finishError

	
	_num20:						;calcula lngitud de numero3
		mov rax, [num2]
		call _countInt

		cmp byte [length], 20
		je _exitFunction			;si ambos son de longitud 20 entonces no es caso especial
		mov byte [flagSpCase], 1		;es caso especial
		ret
		

;---#CALCULA LA LONGITUD DE UN NUMERO

_countInt:
	mov byte [length], 0
divide_loop:
    
	test rax, rax
    	jz _exitFunction
    
    	inc byte [length]				;incrementa contador
    
    	mov rbx, 10					;Divide rax por 10
    	xor rdx, rdx 					;reinicia rdx para la division
    	div rbx
   
    	jmp divide_loop					;loop

;---#CALCULA LA LONGITUD DE UN STRING
	
_lengthCheck:
    	xor rax, rax                  			;Clear registro de rax
    	mov rdi, numString  
	mov byte [length], 0		             	;carga la direccion de memoria de numString en rdi
    
length_loop:
    	cmp byte [rdi + rax], 0      			;observa si tiene terminacion nula
    	je length_done                 
    	inc rax                       			;Incrementa contador
	inc byte [length]
    	jmp length_loop                			;loop

length_done:
	cmp rax, 21
	jg _finishError					;error si es mas largo a 21	
	ret

;--------------END CHEQUEO DE ERRORES------------------------

;--------------ITOA -----------------------------------------

;---#LOOP PARA REALIZAR ITOA

_processLoop:
	cmp qword [numBase],17
	je _exitFunction
	
	cmp byte[flagNegativo], 1				;se asegura de que el primer numero sea o no negativo
	je _printNeg					;realiza print del simbolo negativo
	
_verificarBases:
	cmp qword [numBase], 2
	je _continueLoop
	
	cmp qword [numBase], 8
	je _continueLoop
	
	cmp qword [numBase], 10
	je _continueLoop
	
	cmp qword [numBase], 16
	je _continueLoop
	
	inc qword [numBase]
	jmp _verificarBases
	
_continueLoop:
	call _startItoa
	inc qword [numBase]
	jmp _processLoop

;---#ITOA INICIO

_startItoa:
    	;Llama a ITOA para convertir n a cadena
    	mov rdi, buffer
    	mov rsi, [itoaNum]
    	mov rbx, [numBase]			;Establece la base (Se puede cambiar)
    	call itoa
    	mov r8, rax  					;Almacena la longitud de la cadena
    
    	; Añade un salto de línea
    	mov byte [buffer + r8], 10
    	inc r8
    
    	; Termina la cadena con null
		mov byte [buffer + r8], 0

		mov rax, buffer
		jmp _genericprint

; Definición de la función ITOA
itoa:
    	mov rax, rsi    				; Mueve el número a convertir (en rsi) a rax
    	mov rsi, 0      				; Inicializa rsi como 0 (contador de posición en la cadena)
    	mov r10, rbx   					; Usa rbx como la base del número a convertir

.loop:
	xor rdx, rdx       					; Limpia rdx para la división
    	div r10            				; Divide rax por rbx
    	cmp rbx, 10
    	jbe .lower_base_digits ; Salta si la base es menor o igual a 10
    
    	; Maneja bases mayores que 10
    	movzx rdx, dl
    	mov dl, byte [digitos + rdx]
    	jmp .store_digit
    
.lower_base_digits:
    	; Maneja bases menores o iguales a 10
    	add dl, '0'    ; Convierte el resto a un carácter ASCII
    
.store_digit:
    	mov [rdi + rsi], dl  ; Almacena el carácter en el buffer
    	inc rsi              ; Se mueve a la siguiente posición en el buffer
    	cmp rax, 0           ; Verifica si el cociente es cero
    	jg .loop             ; Si no es cero, continúa el bucle
    
    	; Invierte la cadena
    	mov rdx, rdi
    	lea rcx, [rdi + rsi - 1]
    	jmp reversetest
    
reverseloop:
		mov al, [rdx]
    	mov ah, [rcx]
    	mov [rcx], al
    	mov [rdx], ah
    	inc rdx
    	dec rcx
    
reversetest:
    	cmp rdx, rcx
    	jl reverseloop
    
    	mov rax, rsi  ; Devuelve la longitud de la cadena
    	ret


;ITOA multiplicación
_startItoa_Mul:
    	mov rbx, [numBase]		  ;Establece la base
    	call itoa_mul

		ret

; Definición de la función ITOA
itoa_mul:
    	mov rax, rsi    				; Mueve el número a convertir (en rsi) a rax
    	mov rsi, 0      				; Cantidad de digitos del string
    	mov r10, rbx   					; Usa rbx como la base del número a convertir
    	mov r8, 0 ;Contador para bases low
    	
    	cmp r10, 2 ;Para convertir el número a binario
    	je inicio_binario
    	
    	cmp r10, 8 ;Para convertir el número a octal
    	je base_8
    	
    	cmp r10, 16 ;Para convertir el número a hexadecimal
    	je base_16
    	
    	ret

;BASE 8 - MULTIPLICACIÓN
base_8:
	mov r9, [itoaNumLow] ;Los bits menos significativos
    mov r13, [itoaNumHigh] ;Los bits más significativos

loop_base8_low:
	mov r11, 7 
	and r11, r9 ;Enmascaramiento de los bits menos significativos para obtener los tres menores
	shr r9, 3 ;Se mueven los bits 3 veces a la derecha
	
    mov dl, byte [digitos + r11] ;Se busca el dígito obtenido en el look up table

store_digit_8_low:
    mov [rdi + rsi], dl  ;Almacena el caracter en el string
    inc rsi              ;Se mueve a la siguiente posición del string
    inc r8 ;Se incrementa el contador
    cmp r8, 21 ;Se pregunta si ya se hicieron la cantidad de agrupaciones máxima
	je _frontera8
		
	jmp loop_base8_low

_frontera8:
    mov r11, 1
	and r11, r9 ;Se obtiene el bit que queda del grupo de bits menos significativos
	
	mov r12, 3
	and r12, r13 ;Enmascaramiento de los bits más significativos para obtener los dos menores
	shl r12, 1 ;Se mueven los bits para hacer espacio para lo que contiene el r11 
	or r12, r11 ;Se juntan el r12 y r11
	
	mov dl, byte [digitos + r12] ;Se busca el dígito obtenido en el look up table
	
	mov [rdi + rsi], dl  ;Almacena el caracter en el string
    inc rsi              ;Se mueve a la siguiente posición del string

high_parte:	
	shr r13, 2 ;Se mueven los bits 2 veces a la derecha para descartar los utilizados en la frontera
	mov r8, 0 ;Contador para bases high

loop_base8_high:
	mov r11, 7
	and r11, r13 ;Enmascaramiento de los bits más significativos para obtener los tres menores
	shr r13, 3 ;Se mueven los bits 3 veces a la derecha
	
    mov dl, byte [digitos + r11] ;Se busca el dígito obtenido en el look up table

store_digit_8_high:
    mov [rdi + rsi], dl  ;Almacena el caracter en el string
    inc rsi              ;Se mueve a la siguiente posición del string
    inc r8  ;Se incrementa el contador
    cmp r8, 21 ;Se pregunta si ya se hicieron la cantidad de agrupaciones máxima
	je final_base_8
		
	jmp loop_base8_high	

final_base_8:
	mov rdx, rdi
    lea rcx, [rdi + rsi - 1]
    call reversetest ;Darle vuelta al string
    
    mov rax, buffer
	call _genericprint ;Imprimir el string
    
    ;Imprimir un salto de línea
    mov rax, 1          
    mov rdi, 1          
    mov rsi, espacio    
    mov rdx, 1          
    syscall
    
	ret
	
;BASE 16 - MULTIPLICACIÓN
base_16:
	mov r9, [itoaNumLow] ;Los bits menos significativos
    mov r13, [itoaNumHigh] ;Los bits más significativos

loop_base16_low:
	mov r11, 0xf
	and r11, r9 ;Enmascaramiento de los bits menos significativos para obtener los cuatro menores
	shr r9, 4 ;Se mueven los bits 4 veces a la derecha
	
    mov dl, byte [digitos + r11] ;Se busca el dígito obtenido en el look up table

store_digit_16_low:
    mov [rdi + rsi], dl  ;Almacena el caracter en el string
    inc rsi              ;Se mueve a la siguiente posición del string
    inc r8 ;Se incrementa el contador
    cmp r8, 16 ;Se pregunta si ya se hicieron la cantidad de agrupaciones máxima
	je _inicio_base_16
		
	jmp loop_base16_low

_inicio_base_16:
	mov r8, 0 ;Contador para bases high

loop_base16_high:
	mov r11, 0xf
	and r11, r13 ;Enmascaramiento de los bits menos significativos para obtener los cuatro menores
	shr r13, 4 ;Se mueven los bits 4 veces a la derecha
	
    mov dl, byte [digitos + r11] ;Se busca el dígito obtenido en el look up table

store_digit_16_high:
    mov [rdi + rsi], dl  ;Almacena el caracter en el string
    inc rsi             ;Se mueve a la siguiente posición del string
    inc r8 ;Se incrementa el contador
    cmp r8, 16 ;Se pregunta si ya se hicieron la cantidad de agrupaciones máxima
	je final_base_16
		
	jmp loop_base16_high	

final_base_16:
	mov rdx, rdi
    lea rcx, [rdi + rsi - 1]
    call reversetest ;Darle vuelta al string
    
    mov rax, buffer
	call _genericprint ;Imprimir el string
	

    mov rax, 1          ;syscall number for sys_write
    mov rdi, 1          ;file descriptor 1 (stdout)
    mov rsi, espacio    ;pointer to the newline character
    mov rdx, 1          ;length of the string (1 byte)

    syscall
    
	ret

;BASE 2 - MULTIPLICACIÓN	
inicio_binario:
		mov rsi, 63      			;Cantidad de digitos del string
		
loop_mul:
		xor rdx, rdx       			;Limpia rdx para la división
    	div r10            				;Divide rax por rbx
    	
    	movzx rdx, dl
    
store_digit_mul:

	mov dl, byte [digitos + rdx] ;Se busca el dígito obtenido en el look up table
    	mov [rdi + rsi], dl  ; Almacena el carácter en el buffer
    	dec rsi              ; Se mueve a la siguiente posición en el buffer
    	cmp rax, 0           ; Verifica si el cociente es cero
    	jg loop_mul          ; Si no es cero, continúa el bucle

    	;Invierte la cadena
    	mov rdx, rdi
    	lea rcx, [rdi + rsi - 1]
    	jmp reversetest

;----------------- PRINTS ---------------------

_genericprint:
	mov qword [printCont], 0		;coloca rdx en 0 (contador)
	push rax		;almacenamos lo que esta en rax

_printLoop:
	mov cl, [rax]
	cmp cl, 0
	je _endPrint
	inc qword [printCont]        		;aumenta contador
	inc rax
	jmp _printLoop

_endPrint:
	mov rax, 1
	mov rdi, 1
	mov rdx,[printCont]
	pop rsi			;texto
	syscall
	ret

_getText:			;obtiene el texto
	mov rax, 0
	mov rdi, 0
	mov rsi, numString
	mov rdx, 101
	syscall 
	call _inputCheck	;se asegura de que se ingrese unicamente numeros
	call _lengthCheck
	call _AtoiStart
	ret
	
_getOption:
	mov rax, 0
	mov rdi, 0
	mov rsi, numString
	mov rdx, 101
	syscall 
	call _lengthCheck
	cmp byte [length], 2
	je _exitFunction
	jmp _finishError
	

_printNeg:
	mov rax, 1
	mov rdi, 1
	mov rsi, negSign
	mov rdx, 1 
	syscall
	jmp _verificarBases


_overflowDetected:			;check de overflow
	mov rax, overflowMsg
	call _genericprint
	
	jmp _finishCode
	

_flagInsideError:
	mov byte[flagHasError],1	
	ret
;---------------- END PRINTS --------------------
;-------------------- Finalizacion de codigo 

_finishErrorInput:
	
	cmp byte[flagIsInside], 1
	je _flagInsideError

	jmp _start

_finishError:			;finaliza codigo
	mov rax, errorCode
	call _genericprint
	
	cmp byte[flagIsInside], 1
	je _flagInsideError

	jmp _start
_finishCode:			;finaliza codigo
	mov rax, 60
	mov rdi, 0
	syscall


