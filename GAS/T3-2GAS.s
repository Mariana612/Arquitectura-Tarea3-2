# Creditos a Russ Ross por la base de la implementacion de ITOA. Link al video: https://www.youtube.com/watch?v=D7gabV6tWCE

global _start

.section .data

	text1:		.asciz "Ingrese un numero\n"
	digitos:	.asciz "0123456789ABCDEF"    	# Caracteres que representan los dígitos en base 16
	errorCode:	.asciz "Error: Ingrese un numero valido\n"
	itoaNum:	.quad 0							# numero para procesar en itoa (resultados de suma y resta)
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
	divisionError:	.asciz "Division por cero, desea continuar?\n"
	
.section .bss

	numString:	.resq 13
	num1:		.resq 13
	num2:		.resq 13
	length:		.resb 1
	buffer:		.resb 101		# Buffer para almacenar la cadena de caracteres convertida

.section .text

#------------------ MAIN ------------------------

_start:

	mov $startPrompt, %rax
	call _genericprint

	call _getOption

	mov $2, numBase

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
	call _getUserInput
	;PEGAR EL CODIGO DE UDS AQUI
	jmp _start
	
_getText:                             
    movq $0, %rax
    movq $0, %rdi
    leaq num1(%rip), %rsi
    movq $101, %rdx
    syscall
    call _inputCheck                      # se asegura de que se ingrese unicamente numeros
    call _lengthCheck
    call _AtoiStart
    ret
    
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
	movq $numString, %rsi			; Dirección del buffer de entrada
	xorq %rcx, %rcx					; Limpiar contador

check_input:
	movzb (%rsi, %rcx), %rax		; Cargar el byte actual
	cmp $0xA, %rax
	je input_valid					; Final del string alcanzado
	cmp $'0', %rax
	jb _finishError					; Revisa caracteres no imprimibles
	cmp $'9', %rax
	ja _finishError					; Revisa caracteres no imprimibles
	inc %rcx						; Mover al siguiente byte
	jmp check_input

input_valid:
	ret


# ----------------- ATOI ----------------------------------

_AtoiStart:
    xorq %rbx, %rbx        # reinicia el registro
    xorq %rax, %rax        # reinicia el registro
    leaq num1(%rip), %rcx      # ingresa el num1 a rcx
    jmp _Atoi

_Atoi:
    movb (%rcx), %bl
    cmpb $0xA, %bl
    je _exitFunction       # se asegura de que sea el final del string
    sub $0x30, %rbx        # resta 30h al string para volverlo el numero
    imul $10, %rax         # multiplica el numero almacenado en rax x 10 para volverlo decimal
    add %rbx, %rax         # agrega el ultimo numero obtenido a rax (ej: 10+3=13)
    jc _overflowDetected 
    xorq %rbx, %rbx        # reinicia el registro
    inc %rcx               # incrementa x 1 el rcx (obtiene el siguiente caracter
    jmp _Atoi              # realiza loop

_exitFunction:
    ret

# ----------------- END ATOI ----------------------------------

# -------------- ITOA -----------------------------------------

# LOOP PARA REALIZAR ITOA
_processLoop:

    cmpq $17, counterSumNum(%rip)  # Ajusta el límite del contador
    je _exitFunction
    
    cmpq $101, counterSumNum(%rip)    # Verificar si el contador ha excedido el tamaño del buffer
    jge _exitFunction                  # Salir si el contador excede el tamaño del buffer

    cmpb $1, flag1(%rip)            # se asegura de que el primer numero sea o no negativo
    je _printNeg                    # realiza print del simbolo negativo

_continueLoop:
    movq counterSumNum(%rip), %rbx       # Asigna la base dinámicamente
    call _startItoa
    incq counterSumNum(%rip)
    call _printNewLine
    jmp _processLoop

# ITOA INICIO
_startItoa:
    # Llama a ITOA para convertir n a cadena
    leaq buffer(%rip), %rdi
    movq processNum(%rip), %rsi
    movq counterSumNum(%rip), %r10       # Establece la base 
    call itoa
    movq %rax, %r8                        # Almacena la longitud de la cadena

    # Añade un salto de línea
    movb $'\n', buffer(%rax, %r8)

    # Termina la cadena con null
    movb $0, (%rdi, %r8)
    
    #movq $buffer, %rax
    jmp _printItoa
    
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

# -------------- END ITOA -------------------

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
