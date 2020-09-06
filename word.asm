%include "macro.inc"

	;; ( addr, addr -- addr )
	;; ptr to dict entrypoint, and ptr to string
	;; ptr to word header, or zero if nothing
native "find", find, 0
	mov rsi, w_dict_entry_stub	; dict entrypoint

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

native "drop", drop, 0
	add rsp, 8
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

;;; ( -- )
native "stprint", stprint, 0
	mov [stack_cur], rsp

	.loop:
	mov rax, [stack_cur]
	mov rdi, [stack_base]
	cmp rax, rdi
	jl .p
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
	lea rax, [rax + 8]
	mov [stack_cur], rax
	jmp .loop

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

