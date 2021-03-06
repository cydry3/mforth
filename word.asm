%include "macro.inc"
%define immflag 1

	;; ( addr -- addr )
	;; ptr to string
	;; ptr to word header, or zero if nothing
native "find", find, 0
	pop rdi
	push rdi
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
	pop rdi
	;; successive headerpointer
	push rdi
	push rsi
	add rsi, 8
	call string_equals
	test al, al
	jz .loop

	pop rsi
	pop rdi
	push rsi
	jmp next

	.exit:
	pop rsi
	pop rdi
	xor rsi, rsi
	xor rdi, rdi
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

;;; ( addr -- addr )
;;;  xt address -> xt or zero
;;;  if it's immediate word, return xt address.
;;;  otherwise, return 0.
native "imm", imm, immflag
	pop rax
	mov rdi, rax
;;; flag part
	lea rax, [rax - 1]
	mov al, byte[rax]
	test al, al
	jz .no
	push rdi
	jmp .exit

	.no:
	push 0

	.exit:
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

native ">r", rstore, 0
       pop rax
       sub rstack, 8
       mov [rstack], rax
       jmp next

native "r>", rload, 0
       mov rax, [rstack]
       add rstack, 8
       push rax
       jmp next

native "r@", rcopy, 0
       mov rax, [rstack]
       push rax
       jmp next

native "inbuf", inbuf, 0
	push qword input_buffer
	jmp next

native "word", word, 0
	pop rdi
	call read_word
	push rdx
	jmp next

;;; ( x -- x|nothing )
;;; zerobranch returns x if x is not zero, otherwise
;;; doesn't return.
native "zerobranch", zerobranch, 0
	pop rax
	mov rdi, rax

	test rax, rax
	jnz .exit

	mov rax, [pc]
	add pc, 8
	add pc, rax
	jmp next

	.exit:
	add pc, 8
	push rdi
	jmp next

;;; ( x -- )
;;; jmp if x != 0
;;; consume x. (ref. zerobranch behavier)
native "branch", branch, 0
	pop rax

	test rax, rax
	jz .exit

	mov rax, [pc]
	add pc, 8
	add pc, rax
	jmp next

	.exit:
	add pc, 8
	jmp next

native "lit", lit, 0
       mov rax, [pc]
       add pc, 8
       push rax
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

native "isbranch", isbranch, 0
	mov rax, [ext_dict_here]
	lea rax, [rax - 8]
	mov rax, [rax]
	mov rdi, rax

	cmp rax, xt_zerobranch
	je .eq
	cmp rdi, xt_branch
	je .eq

	push 0
	jmp .exit

	.eq:
	push 1

	.exit:
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
	push rax		; rax = Quotient, rdx = remainder
	jmp next

native "mod", mod, 0
	xor rdx, rdx
	pop rdi
	pop rax
	div rdi			; rdx:rax = rdx:rax div r/m64
	push rdx		; rax = Quotient, rdx = remainder
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
	mov rax, [mode]
	test rax, rax
	jz .interp
	jmp .compile

	.interp:
	mov qword[interpreter_stub], xt_interpreter
	mov pc, interpreter_stub
	jmp .exit

	.compile:
	mov qword[compiler_stub], xt_compiler
	mov pc, compiler_stub
	jmp .exit

	.exit:
	jmp next

native "exec", exec, 0
	pop rdi
	add pc, 8
	mov w, rdi
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

;;; ( -- addr )
native "stbase", stbase, 0
	mov rax, qword[stack_base]
	lea rax, [rax - 8]
	push rax
	jmp next
 
native "counts", counts, 0
       pop rdi
       call string_length
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

native "here", here, 0
	push ext_dict_here
	jmp next

native "last_word", last_def_word_addr, 0
	push last_def_word
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

native "incomp", incomp, 0
	mov qword[mode], 1
	jmp next

native "outcomp", outcomp, 0
	mov qword[mode], 0
	jmp next

native "cellen", cellen, 0
	push 8
	jmp next

native "bytelen", bytelen, 0
	push 1
	jmp next

;;; ( addr, addr, len -- )
native "wordcp", wordcp, 0
	pop rdx
	pop rsi
	pop rdi
	call string_copy
	jmp next

;;; push i_docol address
native "docoli", docoli, 0
	push i_docol
	jmp next

;;; push xt_exit address
native "exit_addr", exit_addr, 0
	push xt_exit
	jmp next

;;; push xt_lit address
native "lit_addr", lit_addr, 0
       push xt_lit
       jmp next

;;; ( call-num a1 a2 a3 a4 a5 a6 -- ret-rax )
;;; syscall does systemcall.
;;; arguments(convention):
;;;   a1=rdi, a2=rsi, a3=rdx, a4=r10, a5=r8, a6=r9
native "syscall", syscall, 0
	pop r9
	pop r8
	pop r10
	pop rdx
	pop rsi
	pop rdi
	pop rax
	syscall
	push rax
	jmp next

;;; ( n -- )
;;; increments here pointer by n
colon "hereinc", hereinc, 0
	dq xt_here
	dq xt_load
	dq xt_plus
	dq xt_here
	dq xt_swap
	dq xt_store
	dq xt_exit

;;; ( c -- )
;;; store c to `here` postion in dicionary.
;;; 1 byte
;;; In compile mode.
colon "c,", defch, 0
	dq xt_here
	dq xt_load
	dq xt_swap
	dq xt_storech
	dq xt_bytelen
	dq xt_hereinc
	dq xt_exit

;;; ( xt -- )
;;; store xt word to `here` postion in dicionary.
;;; 1 cell ( 8 bytes )
;;; In compile mode.
colon ",", defxt, 0
	dq xt_here
	dq xt_load
	dq xt_swap
	dq xt_store
	dq xt_cellen
	dq xt_hereinc
	dq xt_exit

;;; ( flag addr -- )
;;; string(address)
colon "create", create, 0
	dq xt_here
	dq xt_load
	dq xt_last_def_word_addr
	dq xt_load
	dq xt_store

	dq xt_last_def_word_addr
	dq xt_here
	dq xt_load
	dq xt_store

	dq xt_cellen
	dq xt_hereinc

	dq xt_dup		; for word length
	
	dq xt_here
	dq xt_load
	dq xt_cellen
	dq xt_cellen
	dq xt_plus
	dq xt_wordcp

	dq xt_counts		; word length
	dq xt_bytelen		; word length + '\0' (1byte)
	dq xt_plus
	dq xt_hereinc

	dq xt_defch		; flag ( immediate word )

	dq xt_here
	dq xt_load
	dq xt_docoli
	dq xt_store

	dq xt_cellen
	dq xt_hereinc

	dq xt_exit

colon ":", col_comp, 0
	dq xt_scan
	dq xt_bytelen		; flag
	dq xt_inbuf		; addr
	dq xt_create
	dq xt_incomp		; into compiler mode
	dq xt_exit

colon ";", semi_comp, 1
	dq xt_here
	dq xt_load
	dq xt_exit_addr
	dq xt_store

	dq xt_cellen
	dq xt_hereinc

	dq xt_outcomp
	dq xt_exit

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

colon "interpreter", interpreter, 0
	dq xt_scan

	dq xt_inbuf
	dq xt_find
	dq xt_zerobranch
	dq 24
	dq xt_cfa
	dq xt_exec
	dq xt_loop

	dq xt_inbuf
	dq xt_nonum
	dq xt_zerobranch
	dq 16
	dq xt_drop
	dq xt_loop

	dq xt_inbuf
	dq xt_parseui
	dq xt_loop

colon "compiler", compiler, 0
	dq xt_scan

	dq xt_inbuf
	dq xt_find
	dq xt_zerobranch
	dq 128

	dq xt_cfa
	dq xt_imm
	dq xt_zerobranch
	dq 16
	dq xt_exec
	dq xt_loop

	dq xt_inbuf
	dq xt_find	; store xt_word
	dq xt_cfa
	dq xt_here
	dq xt_load
	dq xt_swap
	dq xt_store

	dq xt_cellen
	dq xt_hereinc
	dq xt_loop

	dq xt_inbuf
	dq xt_nonum
	dq xt_zerobranch
	dq 16
	dq xt_drop
	dq xt_loop

	dq xt_isbranch
	dq xt_branch
	dq 48

	dq xt_here		; `lit` for push number
	dq xt_load
	dq xt_lit_addr
	dq xt_store
	dq xt_cellen
	dq xt_hereinc

	dq xt_here		; store a number
	dq xt_load
	dq xt_inbuf
	dq xt_parseui
	dq xt_store
	dq xt_cellen
	dq xt_hereinc

	dq xt_loop

native "dict_entry_stub", dict_entry_stub, 0
