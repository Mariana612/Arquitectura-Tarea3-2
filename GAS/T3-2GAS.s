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

	numString:	.skip 31
	num1:		.skip 21
	num2:		.skip 21
	length:		.skip 1
	buffer:		.skip 101		# Buffer para almacenar la cadena de caracteres convertida

.section .text

#------------------ MAIN ------------------------
.global _start
_start:

	mov $startPrompt, %rax
	call _genericprint

	call _getOption

	movq $2, numBase

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
	
	
_opSuma:

	call _getUserInput

	# SUMA
	mov $sumPrint, %rax
	call _genericprint

	movq num1(%rip), %rax
	addq num2(%rip), %rax  	# Hace la suma
	jc _overflowDetected  	# Check de overflow

	movq %rax, itoaNum(%rip) 	# Inicio itoa suma
	call _processLoop

	jmp _start

_opResta:

	call _getUserInput

	# RESTA
	mov $restPrint, %rax
	call _genericprint

	call _specialCaseSub		# Realiza chequeo de casos especiales (números de longitud 20)

	movq num2(%rip), %rax
	movq num1(%rip), %rsi
	cmp %rax, %rsi
	jge _resta 				# Resta num2-num1
	jl _cambio_resta 		        # Resta num1-num2

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

	subq %rsi, %rax 	# Resta num2-num1
	movq %rax, itoaNum(%rip) 	# Inicio itoa resta

restaCont:
	call _processLoop
	jmp _start
	
_cambio_restaEspecial:
	subq %rax, %rsi 		# Resta num1-num2
	negq %rsi 				# Negar resultado
	movq %rsi, itoaNum(%rip) 	# Inicio itoa resta
	jmp restaCont

_cambio_resta:

	# Si el número es mayor que cierto dígito, se debe negar el resultado
	mov $9900000000000000000, %r10
	cmp %rax, %r10
	jae _cambio_restaEspecial

	subq %rsi, %rax 		# Resta num1-num2
	movq %rsi, itoaNum(%rip) 	# Inicio itoa resta

	jmp restaCont 			# Se imprime el resultado de la resta

_opDivision:

	call _getUserInput

	# División
	mov $divPrint, %rax
	call _genericprint

	movq num1(%rip), %rax
	movq num2(%rip), %rbx

	cmp %rax, %rbx
	jge mayor_num1 	# Salto si num1 es mayor o igual a num2

	xchg %rax, %rbx

mayor_num1:
	# Caso para la división por cero 
	cmp $0, %rbx
	je division_by_zero

	# Resultado se guarda en %rax (cociente)
	xor %rdx, %rdx
	div %rbx

	movq %rax, itoaNum(%rip)
	call _processLoop

	jmp _start

division_by_zero:
	mov $divisionError, %rax
	call _genericprint
	jmp _start

_opMultiplicacion:
	_opMultiplicacion:
	call _getUserInput

	# MULTIPLICACIÓN
	mov $mulPrint, %rax
	call _genericprint
	call _specialCaseSub		# Realiza chequeo de casos especiales (números de longitud 20)

	movq num1(%rip), %rax
	movq num2(%rip), %rsi
	mulq %rsi					# Hace la multiplicación
	jc mulEspecial
	movq %rax, itoaNum(%rip)	# Inicio itoa multiplicación
	call _processLoop

	jmp _start

mulEspecial:
	push %rax
	movq %rdx, itoaNumHigh(%rip)	# Inicio itoa multiplicación
	mov $mul_strHigh, %rdi
	movq itoaNumHigh(%rip), %rsi
	call _startItoa_Mul
	mov $mul_strHigh, %rax
	call _genericprint
	pop %rax
	movq %rax, itoaNumLow(%rip)	# Inicio itoa multiplicación
	mov $mul_strLow, %rdi
	movq itoaNumLow(%rip), %rsi
	call _startItoa_Mul
	mov $mul_strLow, %rax
	call _genericprint

_processLoop_mul:
	cmpq $16, numBase(%rip)
	jg finish
_continueLoop_mul:
	mov $buffer, %rdi
	mov $44, %rcx    # Se puede tener como máximo 21 caracteres
	mov $0, %al      # Se limpia con NULL bytes
	rep stosb        # Se llena la memoria con NULL bytes
	mov $buffer, %rdi
	call _startItoa_Mul
	incq numBase(%rip)
	jmp _processLoop_mul

finish:
	jmp _start
	

    
_getUserInput:                               #Puede que este mal ----------------------------------------------------------------
	mov $text1, %rax
	call _genericprint
	call _getText			# Consigue el texto del usuario

	movb $0, numString(%rip)		# Reinicia numString
	movq %rax, num1(%rip)			# Carga el primer número en num1
	xorq %rax, %rax					# Reinicia rax
	movb $0, numString(%rip)		# Reinicia numString

	mov $text1, %rax				# Hace print inicial
	call _genericprint

	call _getText					# Consigue el texto del usuario
	movq %rax, num2(%rip)			# Carga el primer número en num2

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

_countInt:
	movb $0, length(%rip)

divide_loop:
	test %rax, %rax
	jz _exitFunction
	incb length(%rip)				# Incrementa contador
	mov $10, %rbx					# Divide %rax por 10
	xor %rdx, %rdx 					# Reinicia %rdx para la división
	div %rbx
	jmp divide_loop					# Loop

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
    xorq %rbx, %rbx			# reinicia el registro
    xorq %rax, %rax			# reinicia el registro
    leaq numString(%rip), %rcx		# ingresa el numString a rcx
    jmp _Atoi

_Atoi:
    movb (%rcx), %bl
    cmpb $0xA, %bl
    je _exitFunction		# se asegura de que sea el final del string

    subq $0x30, %rbx		# resta 30h al string para volverlo el numero
    imulq $10, %rax 		# multiplica el numero almacenado en rax x 10 para volverlo decimal
    addq %rbx, %rax			# agrega el ultimo numero obtenido a rax (ej: 10+3=13)
    jc _overflowDetected	# check de overflow

    xorq %rbx, %rbx			# reinicia el registro
    incq %rcx				# incrementa x 1 el rcx (obtiene el siguiente caracter)
    jmp _Atoi			# realiza loop

_exitFunction: 
    ret


# ----------------- END ATOI ----------------------------------

# -------------- ITOA -----------------------------------------

# LOOP PARA REALIZAR ITOA
_processLoop:

    cmpq $17, numBase(%rip)  # Ajusta el límite del contador
    je _exitFunction
    
    cmpq $101, numBase(%rip)    # Verificar si el contador ha excedido el tamaño del buffer
    jge _exitFunction                  # Salir si el contador excede el tamaño del buffer

    cmpb $1, flagNegativo(%rip)            # se asegura de que el primer numero sea o no negativo
    je _printNeg                    # realiza print del simbolo negativo

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

    movq %rsi, %rax             # Mueve el número a convertir (en rsi) a rax
    xorq %rcx, %rcx             # Inicializa rcx como 0 (contador de posición en la cadena)
    movq %rdi, %r9              # Usa r9 como el puntero al buffer
    movq %r10, %rbx              # Carga la base desde el registro r10

.loop:

    xorq %rdx, %rdx          # Limpia rdx para la división
    divq %rbx                # Divide rax por la base
    cmpq $10, %rbx
    jbe .lower_base_digits   # Salta si la base es menor o igual a 10

    # Maneja bases mayores que 10
    movzb %dl, %rdx
    movb digitos(%rdx), %dl   
    jmp .store_digit

.lower_base_digits:
    # Maneja bases menores o iguales a 10
    addb $'0', %dl   # Convierte el resto a un carácter ASCII
    jmp .store_digit

.store_digit:
    movb %dl, (%r9, %rcx)   
    incq %rcx               
    cmpq $0, %rax           
    jg .loop                

    # Reverse the string
    movq %rcx, %rdx         
    leaq -1(%rcx, %r9), %rsi
    movq %r9, %rdi

.reverseloop:
    movb (%rdi), %al        
    movb (%rsi), %ah
    movb %al, (%rsi)
    movb %ah, (%rdi)
    incq %rdi
    decq %rsi
    cmpq %rdi, %rsi         
    jg .reverseloop         

    movq %rcx, %rax         
    ret

reversetest:
    cmpq %rdx, %rcx
    jl .reverseloop

    movq %rsi, %rax  					# Devuelve la longitud de la cadena
    ret


# -------------- END ITOA -------------------

#---------------ITOA MULT--------------------

_startItoa_Mul:
	# Llama a ITOA para convertir n a cadena
	movq numBase(%rip), %rbx	# Establece la base
	call itoa_mul
	ret

itoa_mul:
    movq %rsi, %rax                	# Mueve el número a convertir (en rsi) a rax
    xorq %rsi, %rsi                 	# Cantidad de dígitos del string
    movq %rbx, %r10                 	# Usa rbx como la base del número a convertir
    xorq %r8, %r8                    	# Contador para bases low
    
    cmpq $2, %r10
    je inicio_binario

    cmpq $8, %r10
    je base_8

    cmpq $16, %r10
    je base_16

    ret

#Inicio base 8
base_8:
	movq itoaNumLow(%rip), %r9
	movq itoaNumHigh(%rip), %r13

loop_base8_low:
	movq $7, %r11
	andq %r9, %r11
	shrq $3, %r9

    movb digitos(%r11), %dl

store_digit_8_low:
    movb %dl, (%rdi, %rsi)  # Almacena el carácter en el buffer
    incq %rsi               # Se mueve a la siguiente posición en el buffer
    incq %r8
    cmpq $21, %r8
	je _frontera8
	jmp loop_base8_low

_frontera8:
    movq $1, %r11
	andq %r11, %r9

	movq $3, %r12
	andq %r12, %r13
	shlq $1, %r12
	orq %r11, %r12

	movb digitos(%r12), %dl

	movb %dl, (%rdi, %rsi)  # Almacena el carácter en el buffer
    incq %rsi               # Se mueve a la siguiente posición en el buffer


high_parte:
	shrq $2, %r13
	movq $0, %r8 	# Contador para bases high

loop_base8_high:
	movq $7, %r11
	andq %r11, %r13
	shrq $3, %r13

	movb digitos(%r11), %dl

store_digit_8_high:
    movb %dl, (%rdi, %rsi)  # Almacena el carácter en el buffer
    incq %rsi               # Se mueve a la siguiente posición en el buffer
    incq %r8
    cmpq $21, %r8
	je final_base_8
	jmp loop_base8_high

final_base_8:
	movq %rdi, %rdx
    leaq -1(%rdi, %rsi), %rcx
    call reversetest

    movq $buffer, %rax
	call _genericprint

    movq $1, %rax          # syscall number for sys_write
    movq $1, %rdi          # file descriptor 1 (stdout)
    leaq espacio(%rip), %rsi    # pointer to the newline character
    movq $1, %rdx          # length of the string (1 byte)
    syscall

	ret

#Inicio base 16

base_16:
	movq itoaNumLow(%rip), %r9
	movq itoaNumHigh(%rip), %r13

loop_base16_low:
	movq $0xf, %r11
	andq %r9, %r11
	shrq $4, %r9

    movb digitos(%r11), %dl

store_digit_16_low:
    movb %dl, (%rdi, %rsi)  # Almacena el carácter en el buffer
    incq %rsi               # Se mueve a la siguiente posición en el buffer
    incq %r8
    cmpq $16, %r8
	je _inicio_base_16
	jmp loop_base16_low

_inicio_base_16:
	movq $0, %r8 	# Contador para bases high

loop_base16_high:
	movq $0xf, %r11
	andq %r11, %r13
	shrq $4, %r13

    movb digitos(%r11), %dl

store_digit_16_high:
    movb %dl, (%rdi, %rsi)  # Almacena el carácter en el buffer
    incq %rsi               # Se mueve a la siguiente posición en el buffer
    incq %r8
    cmpq $16, %r8
	je final_base_16
	jmp loop_base16_high

final_base_16:
	movq %rdi, %rdx
    leaq -1(%rdi, %rsi), %rcx
    call reversetest

    movq $buffer, %rax
	call _genericprint

    movq $1, %rax          # syscall number for sys_write
    movq $1, %rdi          # file descriptor 1 (stdout)
    leaq espacio(%rip), %rsi    # pointer to the newline character
    movq $1, %rdx          # length of the string (1 byte)
    syscall

	ret

#Inicio base 2

inicio_binario:
	movq $63, %rsi      				# Cantidad de dígitos del string

loop_mul:
	xorq %rdx, %rdx       				# Limpia rdx para la división
    divq %r10            				# Divide rax por rbx
    movzbl %dl, %edx

store_digit_mul:
	movb digitos(%rdx), %dl
	movb %dl, (%rdi, %rsi)  # Almacena el carácter en el buffer
    decq %rsi               # Se mueve a la siguiente posición en el buffer
    cmpq $0, %rax           # Verifica si el cociente es cero
    jg loop_mul             # Si no es cero, continúa el bucle

    # Invierte la cadena
    movq %rdi, %rdx
    leaq -1(%rdi, %rsi), %rcx
    jmp reversetest


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
    leaq num1(%rip), %rsi
    movq $101, %rdx
    syscall
    
    call _inputCheck                      # se asegura de que se ingrese unicamente numeros
    
    call _clearBuffer
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

