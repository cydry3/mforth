%include "macro.inc"

	;; ( addr, addr -- addr )
	;; ptr to dict entrypoint, and ptr to string
	;; ptr to word header, or zero if nothing
native "find", find, 0
	mov rsi, last_def_word ; dict entrypoint

	push rsi
	.loop:
	;; check if word header is NOT NULL
	pop rsi
	push rsi
	test rsi, rsi
	jz .exit
	pop rsi

	;; next pointer is NOT NULL
	mov rsi, [rsi]
	push rsi
	test rsi, rsi
	jz .exit
	pop rsi

	;; successive headerpointer
	push rsi
	add rsi, 8
	mov rdi, input_buffer
	call string_equals
	test al, al
	jz .loop

	pop rsi
	push rsi
	jmp next

	.exit:
	pop rsi
	xor rsi, rsi
	push rsi
	jmp next


native "cfa", cfa, 0
	pop rdi
;;; previous word part
	add rdi, 8
;;; word part
	.loop:
	push rdi
	mov al, [rdi]
	test al, al
	jz .exit
	pop rdi
	add rdi, 1
	jmp .loop
	.exit:
	pop rdi
	add rdi, 1
;;; flag part
	add rdi, 1
	push rdi
	jmp next

native "bye", bye, 0
	mov rax, 60
	xor rdi, rdi
	syscall

native "docol", docol, 0
	sub rstack, 8
	mov [rstack], pc
	add w, 8
	mov pc, w
	jmp next

native "exit", exit, 0
	mov pc, [rstack]
	add rstack, 8
	jmp next

native "inbuf", inbuf, 0
	push qword input_buffer
	jmp next

native "word", word, 0
	pop rdi
	call read_word
	push rdx
	jmp next

native "zerobranch", zerobranch, 0
	pop rax
	push rax

	test rax, rax
	jnz .exit

	mov rax, [pc]
	add pc, 8
	add pc, rax
	pop rax			; drop stack top
	jmp next

	.exit:
	add pc, 8
	jmp next

native "nonum", nonum, 0
	pop rax
	mov al, byte[rax]
	mov dil, al
	cmp al, '0'
	jl .exit
	cmp dil, '9'
	jg .exit
	push 0
	jmp next

	.exit:
	push 1
	jmp next

;;; ( a -- )
native "drop", drop, 0
	add rsp, 8
	jmp next

native "+", plus, 0
	pop rdi
	pop rax
	add rax, rdi
	push rax
	jmp next

native "-", minus, 0
	pop rdi
	pop rax
	sub rax, rdi
	push rax
	jmp next

native "*", mul, 0
	pop rdi
	pop rax
	mul rdi		; rdx:rax = r/m64 * r/m64
	push rax	; return only 64bits. otherwise treat as overflow.
	jmp next

native "/", div, 0
	xor rdx, rdx
	pop rdi
	pop rax
	div rdi			; rdx:rax = rdx:rax div r/m64
	push rax		; rdx = Quotient, rdx = remainder
	jmp next

native "=", equal, 0
	pop rdi
	pop rax
	cmp rax, rdi
	jz .eq
	push 0
	jmp next
	.eq:
	push 1
	jmp next

native "<", lessthan, 0
	pop rdi
	pop rax
	cmp rax, rdi
	jl .less
	push 0
	jmp next

	.less:
	push 1
	jmp next

native "and", and, 0
	pop rdi
	pop rax

	test rdi, rdi
	jz .A
	mov rdi, 1
	.A:
	test rax, rax
	jz .B
	mov rax, 1
	.B:

	and rax, rdi
	cmp rax, 1
	je .true
	push 0
	jmp next

	.true:
	push 1
	jmp next

native "not", not, 0
	pop rax
	test rax, rax
	jz .zero
	push 0
	jmp next

	.zero:
	push 1
	jmp next

;;; ( a b c -- b c a )
native "rot", rot, 0
	lea rax, [rsp + 16]  	; a
	lea rdi, [rsp +  8]	; b
	mov rcx, [rax]		; tmp <- a
	mov rsi, [rdi]
	mov [rax], rsi		; 0 <- b
	mov [rdi], rcx		; 1 <- tmp(a)

	mov rax, rsp		; c
	mov rcx, [rax]
	mov rsi, [rdi]		; a
	mov [rdi], rcx		; 2 <- c
	mov [rax], rsi		; 3 <- a

	jmp next

;;; ( a b -- b a )
native "swap", swap, 0
	mov rax, rsp		; b
	lea rdi, [rsp + 8]	; a
	mov rcx, [rax]
	mov rsi, [rdi]
	mov [rax], rsi		; 0 <- b
	mov [rdi], rcx		; 1 <- a

	jmp next

;;; ( a -- a a )
native "dup", dup, 0
	mov rax, [rsp]
	push rax
	jmp next

native "loop", loop, 0
	mov qword[interpreter_stub], xt_interpreter
	mov pc, interpreter_stub
	jmp next

native "exec", exec, 0
	pop rdi
	mov qword[interpreter_stub], rdi
	mov pc, xt_interpreter
	add pc, 8
	mov w, [interpreter_stub]
	jmp [w]

native "prints", prints, 0
	pop rdi
	call print_string
	jmp next

native "printui", printui, 0
	pop rdi
	call print_uint
	jmp next

native "parseui", parseui, 0
	pop rdi
	call parse_uint
	push rax
	jmp next

native "parsei", parsei, 0
	pop rdi
	call parse_int
	push rax
	jmp next

;;; ( -- )
native "stprint", stprint, 0
	mov rax, [stack_base]
	lea rax, [rax - 8]
	mov [stack_cur], rax

	.loop:
	mov rax, [stack_cur]
	mov rdi, rsp
	cmp rax, rdi
	jge .p
	xor rax, rax
	xor rdi, rdi
	jmp next
	
	.p:
	mov rax, [stack_cur]
	mov rdi, [rax]
	call print_uint
	mov rdi, ' '
	call print_char

	mov rax, [stack_cur]
	lea rax, [rax - 8]
	mov [stack_cur], rax
	jmp .loop

native ".", popprint, 0
	pop rdi
	call print_uint
	mov rdi, ' '
	call print_char
	jmp next

native "key", key, 0
	call read_char
	push rax
	jmp next

native "emit", emit, 0
	pop rdi
	call print_char
	jmp next

native "mem", mem, 0
	push forth_mem
	jmp next

native "status", status, 0
	push mode
	jmp next

;;; ( address data -- )
native "!", store, 0
	pop rdi
	pop rax
	mov [rax], rdi
	jmp next

;;; ( address char -- )
native "c!", storech, 0
	pop rdi
	pop rax
	mov byte[rax], dil
	jmp next

;;; ( address -- value )
native "@", load, 0
	pop rax
	mov rax, [rax]
	push rax
	jmp next

;;; ( address -- char )
native "c@", loadch, 0
	pop rax
	mov al, byte[rax]
	movzx rax, al
	push rax
	jmp next

native ":", col_comp, 0
	mov qword[mode], 1
	jmp next

native ";", sem_comp, 0
	mov qword[mode], 0
	jmp next

;;; ( a b -- bool )
colon "or", or, 0
	dq xt_dup		; b2 -> ( a b b )
	dq xt_rot		; ( b b a )
	dq xt_dup		; ( b b a a )

	dq xt_and		; ( b b c )
	dq xt_not		; ( b b m )

	dq xt_rot		; ( b m b )
	dq xt_rot		; ( m b b )
	dq xt_and		; ( m d )
	dq xt_not		; ( m n )

	dq xt_and		; ( x )
	dq xt_not		; ( y )

	dq xt_exit

;;; ( a b -- bool )
;;; greter
colon ">", greater, 0
	dq xt_lessthan
	dq xt_not
	dq xt_exit

colon "number", number, 0
	dq xt_inbuf
	dq xt_word
	dq xt_drop
	dq xt_inbuf
	dq xt_parsei
	dq xt_exit

colon "scan", scan, 0
	dq xt_inbuf
	dq xt_word
	dq xt_drop
	dq xt_exit

colon "printb", printb, 0
	dq xt_inbuf
	dq xt_prints
	dq xt_exit

colon ".s", dotst, 0
	dq xt_stprint
	dq xt_exit

native "dict_entry_stub", dict_entry_stub, 0

;;; interpreter loop
	section .data
interpreter_stub: dq 0
	section .text
xt_interpreter: dq i_docol
i_interpreter:
	dq xt_scan

	dq xt_find
	dq xt_zerobranch
	dq 16
	dq xt_cfa
	dq xt_exec

	dq xt_inbuf
	dq xt_nonum
	dq xt_zerobranch
	dq 16
	dq xt_drop
	dq xt_loop

	dq xt_inbuf
	dq xt_parseui
	dq xt_loop

