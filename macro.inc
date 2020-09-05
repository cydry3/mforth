;; last word
%define last_word 0

;; ( word, ident, flag )
%macro native 3
section .data
w_ %+ %2 :
      dq last_word
      db %1, 0
      dq %3
xt_ %+ %2: dq i_ %+ %2
section .text
i_ %+ %2:
%define last_word w_ %+ %2
%endmacro
