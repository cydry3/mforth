%include "macro.inc"

native "find", find
native "cfa", cfa

native "+", plus
    pop rax
    add [rsp], rax
    jmp next