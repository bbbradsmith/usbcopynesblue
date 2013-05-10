             .title "76 in 1 Reader Plugin"


;10/24/00 
;Written by KH
;Version 1.0
             
             ;vectors for standard system calls

send_byte:   .equ 0200h
baton:       .equ 0203h

temp1:       .equ 00e0h
temp1_lo:    .equ 00e0h
temp1_hi:    .equ 00e1h
temp2:       .equ 00e2h
temp2_lo:    .equ 00e2h
temp2_hi:    .equ 00e3h
temp3:       .equ 00e4h
temp3_lo:    .equ 00e4h
temp3_hi:    .equ 00e5h


             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "76 in 1" 
             .db " single multicart only",0

             .fill 0400h-*,00h    ;all plugins must reside at 400h
             

; 8000h:
;
; 0 - 16K page
; 1
; 2
; 3
; 4 - 32K page (4 bits)
; 5 
; 6 - 32K (0)/16K (1)
; 7 - bank

;8001h:

; 0 - bank

; 0 x
; 1 x
; 2 x
; 3 x
; 4 y
; 5 y
; 6 0
; 7 0
;     
;    
; 00yy xxxx
; 0yyx xxx0
; 000x xxx0 -> stored
;
; 0yyx xxx0 R
; yyxx xx00 R
; yxxx x000 



             lda #04h
             jsr send_byte
             
             
             lda #00h
             jsr send_byte
             lda #020h
             jsr send_byte
             lda #01h
             jsr send_byte    ;send header
             
             lda #0
             sta temp2_lo
             lda #040h
             sta temp2_hi


dl_loop:     lda temp2_lo
             asl a
             pha
             and #1eh
             sta temp3_lo    ;first 4 bits
             pla
             asl a
             asl a
             and #080h
             ora temp3_lo
             sta 08000h
             lda #00h
             adc #00h
             sta 08001h      ;OR on next bit
             
             
             
             lda #00h
             sta temp1_lo
             lda #080h
             sta temp1_hi     ;set to 080h
             ldy #0

dl_loop2:    lda (temp1),y 
             jsr send_byte
             iny
             bne dl_loop2
             inc temp1_hi
             bne dl_loop2
             inc temp2_lo
             dec temp2_hi
             bne dl_loop


             lda #00h
             jsr send_byte
             lda #00h
             jsr send_byte
             lda #00h
             jsr send_byte
             rts



             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
