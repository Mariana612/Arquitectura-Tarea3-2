; Creditos a Russ Ross por la base de la implementacion de ITOA. Link al video: https://www.youtube.com/watch?v=D7gabV6tWCE

global _start

section .data
	text1 db "Ingrese un numero", 0xA, 0 					
	digitos db '0123456789ABCDEF'     						;Caracteres que representan los dígitos en base 16
	errorCode db "Error: Ingrese un numero valido", 0xA, 0
	itoaNum dq 0											;numero para procesar en itoa (resultados de suma y resta)
	numBase dq 2											;numero utilizado para la base del itoa
	flagNegativo db 0										;flag que indica que el numero es negativo
	flagSpCase db 0											;flag del caso especial de la resta
	negSign db "-" 
	sumPrint db "Print de sumas:", 0xA, 0
	restPrint db "Print de restas:", 0xA, 0
	divPrint db "Print de division:", 0xA, 0
	overflowMsg db "ERROR: Overflow", 0xA, 0
	startPrompt db "Que desea realizar? 1. suma 2. resta 3. division 4. multiplicacion 5.Finalizar Programa",0xA,0
	compare_num dq "18446744073709551615"					;indica el numero maximo a ingresar
	printCont dq 0
	divisionError db "Division por cero", 0xA, 0          
	
	

section .bss
	numString resq 13 
	num1 resq 13
	num2 resq 13
	length resb 1
	buffer  resb 101   									;Buffer para almacenar la cadena de caracteres convertida

section .text

;------------------ MAIN ------------------------
_start:
	mov rax, startPrompt
	call _genericprint
	
	call _getOption
	mov qword [numBase],2

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

_opSuma:
	call _getUserInput

	;#SUMA
	mov rax, sumPrint
	call _genericprint
	mov rax, [num1]
    	add rax, [num2]			;Hace la suma
	jc _overflowDetected		;check de overflow
	mov [itoaNum], rax		;inicio itoa suma
	call _processLoop
	jmp _start
	

_opResta:
	call _getUserInput

	;#RESTA
	mov rax, restPrint
	call _genericprint
	call _specialCaseSub		;realiza chequeo de casos especiales (numeros de len 20)

	mov rax, [num2]
	mov rsi, [num1]
	cmp rax, rsi	
	jge _resta ;Resta num2-num1
    jl _cambio_resta ;Resta num1-num2

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
    
	sub rax, rsi ;Resta num2-num1
	mov [itoaNum], rax ;inicio itoa resta

restaCont:
	call _processLoop
	jmp _start

_cambio_restaEspecial:
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
	call _getUserInput
		
	;#Division
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

	jmp _start

division_by_zero:
	mov rax, divisionError
	call _genericprint
	call _finishCode
	
_opMultiplicacion:
	call _getUserInput
	;PEGAR EL CODIGO DE UDS AQUI
	jmp _start
	

_getUserInput:	
	
	mov rax, text1
	call _genericprint
	call _getText			;Consigue el texto del usuario


	mov byte[numString], 0		;reinicia numString
	mov qword [num1], rax		;carga el primer numero en num1
	xor rax, rax			;reinicia rax
	mov byte[numString], 0		;reinicia numString
	
	mov rax, text1   		;Hace print inicial
	call _genericprint
	
	call _getText			;Consigue el texto del usuario
	mov qword [num2], rax		;carga el primer numero en num2

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
        	jb _finishError				;Revisa caracteres no imprimibles
        	cmp rax, '9'
        	ja _finishError				;Revisa caracteres no imprimibles
        	inc rcx					;Mover al siguente byte
        	jmp check_input

	input_valid:
		ret

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

   	mov rax , buffer
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
    	jmp .store_digit
    
.store_digit:
    	mov [rdi + rsi], dl  ; Almacena el carácter en el buffer
    	inc rsi              ; Se mueve a la siguiente posición en el buffer
    	cmp rax, 0           ; Verifica si el cociente es cero
    	jg .loop             ; Si no es cero, continúa el bucle
    
    	; Invierte la cadena
    	mov rdx, rdi
    	lea rcx, [rdi + rsi - 1]
    	jmp .reversetest
    
.reverseloop:
   	mov al, [rdx]
    	mov ah, [rcx]
    	mov [rcx], al
    	mov [rdx], ah
    	inc rdx
    	dec rcx
    
.reversetest:
    	cmp rdx, rcx
    	jl .reverseloop
    
    	mov rax, rsi  ; Devuelve la longitud de la cadena
    	ret

;----------------- END ITOA -------------------

;-----------------Print Generico---------------

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

;----------------- PRINTS ---------------------

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
	jmp _continueLoop


_overflowDetected:			;check de overflow
	mov rax, overflowMsg
	mov rdx, 16
	call _genericprint


;---------------- END PRINTS --------------------
;-------------------- Finalizacion de codigo 

_finishError:			;finaliza codigo
	mov rax, errorCode
	call _genericprint

_finishCode:			;finaliza codigo
	mov rax, 60
	mov rdi, 0
	syscall


