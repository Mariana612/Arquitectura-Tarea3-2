# Creditos a Russ Ross por la base de la implementacion de ITOA. Link al video: https://www.youtube.com/watch?v=D7gabV6tWCE



.section .data

	text1:		.asciz "Ingrese un numero\n"
	digitos:	.asciz "0123456789ABCDEF"    	# Caracteres que representan los dígitos en base 16
	errorCode:	.asciz "Error: Ingrese un numero valido\n"
	errorInvalidInput: .asciz "Error: Numero invalido\n"
	errorLengthChar: .asciz "Error: Mas caracteres de lo espererado\n"
	getOptionError: .asciz "Error: Al conseguir la opcion\n"
	itoaNum:	.quad 0							# numero para procesar en itoa (resultados de suma y resta)
	itoaNumHigh:    .quad 0
	itoaNumLow:     .quad 0
	numBase:	.quad 2							# numero utilizado para la base del itoa
	flagNegativo:	.byte 0						# flag que indica que el numero es negativo
	flagSpCase:	.byte 0							# flag del caso especial de la resta
	negSign:	.asciz "-" 
	sumPrint:	.asciz "Print de sumas:\n"
	restPrint:	.asciz "Print de restas:\n"
	divPrint:	.asciz "Print de division:\n"
	overflowMsg:	.asciz "ERROR: Overflow\n"
	startPrompt:	.asciz "Escoja una Opcion: 1. suma 2. resta 3. division 4. multiplicacion 5.Finalizar Programa\n"
	printCont:	.quad 0
	mulPrint: .ascii "Print de multiplicaciones:\n\0"
	compare_num: .quad 18446744073709551615
	divisionError:	.asciz "Division por cero, desea continuar?\n"
	mul_strHigh: .ascii "0000000000000000000000000000000000000000000000000000000000000000\0"
	mul_strLow: .ascii "0000000000000000000000000000000000000000000000000000000000000000\n\0"
	espacio: .byte 10
	newline: .asciz "\n" 

	
.section .bss

    .lcomm numString, 31
    .lcomm num1, 21         
    .lcomm num2, 21         
    .lcomm length, 1        
    .lcomm buffer, 101 

.section .text

#------------------ MAIN ------------------------
.global _start
_start:
	#call _cleanRegisters     # output = segmentation fault
	mov $startPrompt, %rax
	call _genericprint

	call _getOption

	#movq $2, numBase

	cmpb $'1', numString(%rip)
	je _opSuma

	cmpb $'2', numString(%rip)
	je _opResta

	cmpb $'3', numString(%rip)
	je _opDivision

	cmpb $'4', numString(%rip)
	je _opMultiplicacion

	cmpb $'5', numString(%rip)
	je _finishCode
	
	call _cleanRegisters
	jmp _start


_cleanRegisters:
	movq length, %rdi
	movq $101, %rcx
	movb $0, %al
	rep stosb

	movq $numString, %rdi
	movq $104, %rcx
	movb $0, %al
	rep stosb

	ret
	
_opSuma:
    call _getUserInput

    # SUMA
    movq num1(%rip), %rax    # Load num1 into %rax
    movq num2(%rip), %rbx    # Load num2 into %rbx
    addq %rbx, %rax    # Hace la suma
    jc _overflowDetected      # Check de overflow

    movq %rax, itoaNum(%rip)    # Inicio itoa suma
    movq $sumPrint, %rax
    call _genericprint

    call _processLoop
    jmp _finishCode

_opResta:

	call _getUserInput

	# RESTA
	mov $restPrint, %rax
	call _genericprint

	call _specialCaseSub		# Realiza chequeo de casos especiales (números de longitud 20)

	movq num2(%rip), %rax
	movq num1(%rip), %rsi
	cmp %rax, %rsi
	jg _resta 				# Resta num2-num1
	jle _cambio_resta 		        # Resta num1-num2

_restaEspecial:

	subq %rsi, %rax  		# Resta num2-num1
	negq %rax 				# Negar resultado
	movq %rax, itoaNum(%rip) 	# Inicio itoa resta
	jmp restaCont

_resta:

	# Si el número es mayor que cierto dígito, se debe negar el resultado
	mov $9900000000000000000, %r10
	cmp %rsi, %r10
	jae _restaEspecial

	movb $1, flagNegativo(%rip)    # Indica que el número es negativo
    subq %rsi, %rax                 # Resta num2-num1
    movq %rax, itoaNum(%rip)       # Inicio itoa resta

restaCont:
	call _processLoop
    movb $0, flagNegativo(%rip)
    jmp _finishCode
    call _processLoop
    call _finishCode
	
_cambio_restaEspecial:
	movb $1, flagNegativo(%rip)    # Indica que el número es negativo
    subq %rax, %rsi                 # Resta num1-num2
    negq %rsi                       # Negar resultado
    movq %rsi, itoaNum(%rip)        # Inicio itoa resta               
    jmp restaCont

_cambio_resta:

	# Si el número es mayor que cierto dígito, se debe negar el resultado
    movq $9900000000000000000, %r10
    cmpq %rax, %r10
    jae _cambio_restaEspecial
    
    subq %rax, %rsi                 # Resta num1-num2
    movq %rsi, itoaNum(%rip)        # Inicio itoa resta
    
    jmp restaCont                   # Se imprime el resultado de la resta

_opDivision:
	
	# DIVISIÓN
    movq $divPrint, %rax
    call _genericprint

    call _getUserInput

    movq num1(%rip), %rax
    movq num2(%rip), %rbx
    cmpq %rax, %rbx
    jle mayor_num1                    # Salto si num1 es mayor o igual a num2
    xchgq %rax, %rbx

mayor_num1:
    # Caso para la división por cero
    cmpq $0, %rbx
    je division_by_zero

    # Resultado se guarda en rax (cociente)
    xorq %rdx, %rdx
    divq %rbx

    movq %rax, itoaNum(%rip)
    call _processLoop

    jmp _finishCode

division_by_zero:
	mov $divisionError, %rax
	call _genericprint
	jmp _start

_opMultiplicacion:
	jmp _start
	
    
_getUserInput:                               #Puede que este mal ----------------------------------------------------------------
	mov $text1, %rax
	call _genericprint
	call _getText			# Consigue el texto del usuario

	movb $0, numString		# Reinicia numString
	movq %rax, num1			# Carga el primer número en num1
	xorq %rax, %rax					# Reinicia rax
	movb $0, numString		# Reinicia numString

	mov $text1, %rax				# Hace print inicial
	call _genericprint

	call _getText					# Consigue el texto del usuario
	movq %rax, num2			# Carga el primer número en num2

	ret


#----------------- CHEQUEO DE ERRORES -----------------------

#---chequea que el caracter ingresado sea un int

_inputCheck:
	movq $numString, %rsi			# Dirección del buffer de entrada
	xorq %rcx, %rcx					# Limpiar contador

check_input:
	movzb (%rsi, %rcx), %rax		# Cargar el byte actual
	cmp $0xA, %rax
	je input_valid					# Final del string alcanzado
	cmp $0, %rax                   # Comprobar el final del string
    je input_valid                 # Final del string alcanzado
	cmp $'0', %rax
	jb input_invalid					# Revisa caracteres no imprimibles
	cmp $'9', %rax
	ja input_invalid					# Revisa caracteres no imprimibles
	inc %rcx						# Mover al siguiente byte
	jmp check_input

input_valid:
	ret

input_invalid:
	movq $errorInvalidInput, %rax
	call _genericprint
	jmp _start

_specialCaseSub:
	movq num1(%rip), %rax
	call _countInt					# Calcula la longitud de num1
	# ---------------
	cmpb $20, length(%rip)				# Compara que el tamaño es 20
	je _num20
	movq num2(%rip), %rax
	call _countInt
	cmpb $20, length(%rip)
	jne _exitFunction				# Si ambos son menores a 20, no es caso especial
	movb $1, flagSpCase(%rip)			# Caso especial
	ret

_num20:						# Calcula la longitud de num2
	movq num2(%rip), %rax
	call _countInt
	cmpb $20, length(%rip)
	je _exitFunction			# Si ambos son de longitud 20 entonces no es caso especial
	movb $1, flagSpCase(%rip)		# Es caso especial
	ret

#-----------Calcula longitud de un numero

_countInt:
	movb $0, length(%rip)

divide_loop:
	testq %rax, %rax
	jz _exitFunction
	
	incb length(%rip)				# Incrementa contador
	
	mov $10, %rbx					# Divide %rax por 10
	xor %rdx, %rdx 					# Reinicia %rdx para la división
	divq %rbx
	
	jmp divide_loop					# Loop

#-----------Calcula longitud de un string

_lengthCheck:
	xor %rax, %rax                  	# Clear registro de %rax
	movq $numString, %rdi
	movb $0, length(%rip)				# Carga la dirección de memoria de numString en %rdi

length_loop:
	cmpb $0, (%rdi, %rax)      		 #Observa si tiene terminación nula
	je length_done
	inc %rax                       	# Incrementa contador
	incb length(%rip)
	jmp length_loop                	# Loop

length_done:
	cmp $21, %rax
	jg errorLength			# Error si es más largo a 21
	ret
	
errorLength:
	movq $errorLengthChar, %rax
	call _genericprint
	jmp _start

# ----------------- ATOI ----------------------------------

_AtoiStart:
    xorq %rbx, %rbx         # Reinicia el registro
    xorq %rax, %rax         # Reinicia el registro
    leaq numString(%rip), %rcx   # Ingresa el numString a rcx
    testq %rcx, %rcx        # Comprueba si el puntero al buffer es nulo
    je _exitFunction        # Salta si es nulo
    jmp _Atoi

_Atoi:
    movb (%rcx), %bl
    cmpb $0xA, %bl
    je _exitFunction       # Se asegura de que sea el final del string

    subq $0x30, %rbx       # Resta 30h al string para volverlo el número
    imulq $10, %rax        # Multiplica el número almacenado en rax x 10 para volverlo decimal
    addq %rbx, %rax        # Agrega el último número obtenido a rax (ej: 10+3=13)
    jc _overflowDetected  # Check de overflow

    xorq %rbx, %rbx        # Reinicia el registro
    incq %rcx              # Incrementa x 1 el rcx (obtiene el siguiente caracter)
    jmp _Atoi              # Realiza loop

_exitFunction: 
    ret


# ----------------- END ATOI ----------------------------------

# -------------- ITOA -----------------------------------------

# LOOP PARA REALIZAR ITOA
_processLoop:

    cmpq $17, numBase(%rip)
    je _exitFunction

    cmpb $1, flagNegativo(%rip)       # Se asegura de que el primer número sea o no negativo
    je _printNeg                      # Realiza el print del símbolo negativo

_continueLoop:
    movq numBase(%rip), %rbx       # Asigna la base dinámicamente
    call _startItoa
    incq numBase(%rip)
    movq $newline, %rax
    call _genericprint
    jmp _processLoop

# ----------------------------------------------------ITOA INICIO
_startItoa:
    # Llama a ITOA para convertir n a cadena
    movq $buffer, %rdi
    movq itoaNum(%rip), %rsi
    movq numBase(%rip), %rbx
    
    cmpq $0, %rbx            # Comprueba si la base es cero
    je division_by_zero   # Salta si es cero
    
    call itoa

    movq %rax, %r8  					# Almacena la longitud de la cadena

    # Añade un salto de línea
    movb $'\n', buffer(%rax, %r8)

    # Termina la cadena con null
    movb $0, (%rdi, %r8) 

    movq $buffer, %rax
    jmp _genericprint



# Definición de la función ITOA
itoa:
    movq %rsi, %rax                 # Mueve el número a convertir (en rsi) a rax
    xorq %rsi, %rsi                 # Inicializa rsi como 0 (contador de posición en la cadena)
    movq %rbx, %r10                 # Usa rbx como la base del número a convertir

.loop:
    xorq %rdx, %rdx                 # Limpia rdx para la división
    divq %r10                       # Divide rax por rbx
    cmpq $10, %rbx
    jbe .lower_base_digits          # Salta si la base es menor o igual a 10

    # Maneja bases mayores que 10
    movzbl %dl, %edx
    movb digitos(,%rdx,1), %dl
    jmp .store_digit

.lower_base_digits:
    # Maneja bases menores o iguales a 10
    addb $'0', %dl                   # Convierte el resto a un carácter ASCII

.store_digit:
    movb %dl, (%rdi,%rsi)           # Almacena el carácter en el buffer
    incq %rsi                        # Se mueve a la siguiente posición en el buffer
    cmpq $0, %rax                    # Verifica si el cociente es cero
    jg .loop                         # Si no es cero, continúa el bucle

    # Invierte la cadena
    movq %rdi, %rdx
    leaq -1(%rdi,%rsi,1), %rcx
    jmp reversetest

reverseloop:
    movb (%rdx), %al
    movb (%rcx), %ah
    movb %ah, (%rdx)
    movb %al, (%rcx)
    incq %rdx
    decq %rcx

reversetest:
    cmpq %rdx, %rcx
    jl reverseloop

    movq %rsi, %rax                  # Devuelve la longitud de la cadena
    ret

# -------------- END ITOA -------------------

#---------------ITOA MULT--------------------



#--------------FIN ITOA MULT-----------------


#---------------PRINT GENERICO---------------

_genericprint:
    movq $0, printCont          # coloca printCont en 0 (contador)
    pushq %rax                  # almacenamos lo que está en rax

_printLoop:
    movb (%rax), %cl
    cmpb $0, %cl
    je _endPrint
    incq printCont              # aumenta contador
    incq %rax
    jmp _printLoop

_endPrint:
    movq $1, %rax
    movq $1, %rdi
    movq printCont, %rdx
    popq %rsi                   
    syscall
    ret
    
#--------------------------------------------------------
_getText:                             
    movq $0, %rax
    movq $0, %rdi
    movq $numString, %rsi
    movq $101, %rdx
    syscall
    
    call _inputCheck                      # se asegura de que se ingrese unicamente numeros
    call _lengthCheck
    
    
    call _AtoiStart
    ret
 
    
_getOption:
	movq $0, %rax
	movq $0, %rdi
	movq $numString, %rsi
	movq $101, %rdx
	syscall
	call _lengthCheck
	cmpb $2, length
	je _exitFunction
	jmp _finishError


_clearBuffer:
    movq $0, %rax          # System call number for sys_read
    movq $0, %rdi          # File descriptor 0 (stdin)
    leaq buffer(%rip), %rsi    # Buffer para almacenar la entrada
    movq $100, %rdx        # Longitud del buffer
    syscall

    ret

_printNeg:
	movq $1, %rax
	movq $1, %rdi
	leaq negSign(%rip), %rsi
	movq $1, %rdx
	syscall
	jmp _continueLoop

_overflowDetected:		# Check de overflow
	movq $overflowMsg, %rax
	call _genericprint
	jmp _start

_finishError:		# Finaliza código
	movq $errorCode, %rax
	call _genericprint
	jmp _start

_finishCode:		# Finaliza código
	movq $60, %rax
	movq $0, %rdi
	syscall

