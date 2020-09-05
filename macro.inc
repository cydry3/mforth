;; last word
%define last_word 0

;; ( word, ident, flag )
%macro native 3
section .data
%%last_word:
      dq last_word
      db %1, 0
      dq %3
xt_%2: dq i_%2
section .text
i_%2:
%define last_word %%last_word
%endmacro

;; ( word, ident ) default flag = 0
%macro native 2
native %1, %2, 0
%endmacro