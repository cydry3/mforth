section .text

string_length:
    xor rax, rax
.loop:
    cmp byte[rdi + rax], 0
    je .end
    inc rax
    jmp .loop    
.end:   
    ret

print_string:
    push rdi
    call string_length
    pop rdi
    mov rdx, rax
    mov rax, 1
    mov rsi, rdi
    mov rdi, 1
    syscall
    ret

print_char:
    mov rax, rdi
    sub rsp, 1
    mov byte[rsp], al
    mov rax, 1
    mov rdi, 1		; stdout
    mov rsi, rsp
    mov rdx, 1
    push rcx
    syscall
    pop rcx
    add rsp, 1
    ret

print_newline:
    mov byte[rdi], 10
    jmp print_char


print_uint:
    mov rax, rdi
    mov rdi, rsp

    push 0
    sub rsp, 16

    dec rdi
    mov r8, 10
.loop:
    xor rdx, rdx	; rdx:rax
    div r8   		; divisor
    or dl, 0x30		; +0x30('0')
    dec rdi
    mov [rdi], dl
    test rax, rax
    jnz .loop

    call print_string

    add rsp, 24
    ret


print_int:
    test rdi, rdi
    jns print_uint
    push rdi
    mov rdi, '-'
    call print_char
    pop rdi
    neg rdi
    jmp print_uint
    ret


string_equals:
    mov al, byte[rdi]
    cmp al, byte[rsi]
    jne .no
    inc rdi
    inc rsi
    test al, al
    jnz string_equals
    mov rax, 1
    ret
    .no:
    xor rax, rax
    ret


read_char:
    push 0
    xor rax, rax
    xor rdi, rdi
    mov rsi, rsp	;buf
    mov rdx, 1		;size
    syscall
    pop rax
    ret 

read_word:
    push r14
    push r15
    xor r14, r14
    xor r15, rsi
    dec r15

    .A:
    push rdi
    call read_char
    pop rdi
    cmp al, ' '
    je .A
    cmp al, 10
    je .A
    cmp al, 13
    je .A
    cmp al, 9
    je .A
    test al, al
    jz .C

    .B:
    mov byte[rdi + r14], al
    inc r14

    push rdi
    call read_char
    pop rdi
    cmp al, ' '
    je .C
    cmp al, 10
    je .C
    cmp al, 13
    je .C
    cmp al, 9
    je .C
    test al, al
    jz .C
    cmp r14, r15
    je .D

    jmp .B

    .C:
    mov byte[rdi + r14], 0
    mov rax, rdi

    mov rdx, r14
    pop r15
    pop r14
    ret

    .D:
    xor rax, rax
    pop r15
    pop r14
    ret

; rdi points to a string
; returns rax: number, rdx : length
parse_uint:
    mov r8, 10
    xor rax, rax
    xor rcx, rcx
.loop:
    movzx r9, byte[rdi + rcx]
    cmp r9, '0'
    jb .end
    cmp r9, '9'
    ja .end
    xor rdx, rdx
    mul r8
    and r9b, 0x0f
    add rax, r9
    inc rcx
    jmp .loop
.end:
    mov rdx, rcx
    ret

; rdi points to a string
; returns rax: number, rdx : length
parse_int:
    mov rax, rdi
    mov r8b, byte[rdi]
    cmp r8b, '-'
    je .B
    jmp parse_uint
.B:    
    inc rdi
    call parse_uint
    neg rax
    inc rdx
.end:
    ret 


string_copy:
    push rdi
    push rsi
    push rdx
    call string_length
    pop rdx
    pop rsi
    pop rdi
    add rax, 1		; add byte cell for null terminate '0'.(string)
    cmp rax, rdx	; src size < dst size
    jg .end

    mov rcx, rax	; store len
    xor r8, r8		; counter reset
.loop:
    mov al, byte[rdi + r8]
    mov byte[rsi + r8], al
    inc r8
    cmp r8, rcx
    jne .loop
    mov byte[rsi + r8], 0	; add null terminate '0' for string.
.end:    
    ret

	
exit:
    mov rax, 60
    xor rdi, rdi
    syscall
