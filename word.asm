%include "macro.inc"

	;; ( addr -- addr )
	;; ptr to string
	;; ptr to word header, or zero if nothing
native "find", find, 0
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

	call string_equals
	test al, al
	jz .loop

	pop rsi
	mov rax, rsi
	ret

	.exit:
	pop rsi
	xor rsi, rsi
	xor rax, rax
	ret


native "cfa", cfa, 0
;;; previous word
	add rdi, 8
;;; word
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
;;; flag
	add rdi, 1
	mov rax, rdi
	ret

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

native "drop", drop, 0
	add rsp, 8
	jmp next

native "loop", loop, 0
	mov qword[interpreter_stub], xt_interpreter
	mov pc, interpreter_stub
	jmp next

native "prints", prints, 0
	pop rdi
	call print_string
	jmp next

colon "scan", scan, 0
	dq xt_inbuf
	dq xt_word
	dq xt_drop
	dq xt_exit

colon "printb", printb, 0
	dq xt_inbuf
	dq xt_prints
	dq xt_exit

native "dict_entry_stub", dict_entry_stub, 0

;;; interpreter loop
	section .data
interpreter_stub: dq 0
	section .text
xt_interpreter: dq i_docol
i_interpreter:
	dq xt_scan
	dq xt_printb
	dq xt_loop
