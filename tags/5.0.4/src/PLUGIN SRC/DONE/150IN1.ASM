             .title "Golden Game 150 in 1 Reader Plugin"


;06/11/00 
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
             
             .db "Golden Game 150 in 1" 
             .db " single multicart only",0

             .fill 0400h-*,00h    ;all plugins must reside at 400h
             
             lda #04h
             jsr send_byte
             
             
             lda #00h
             jsr send_byte
             lda #020h
             jsr send_byte
             lda #01h
             jsr send_byte    ;send header
             
             lda #020h        ;read first 1Mbyte ROM
             sta temp2_hi
             lda #0
             sta temp2_lo
             
dl_loop:     lda #00h
             sta temp1_lo
             lda #080h
             sta temp1_hi     ;set to 080h
             ldy #0
             ldx temp2_lo
             sta 08000h,x

dl_loop2:    lda (temp1),y 
             jsr send_byte
             iny
             bne dl_loop2
             inc temp1_hi
             bne dl_loop2
             inc temp2_lo
             dec temp2_hi
             bne dl_loop

             lda #0
             sta temp2_lo
             lda #020h        ;read second 1Mbyte ROM
             sta temp2_hi
             
dl_loop3:    lda #00h
             sta temp1_lo
             lda #080h
             sta temp1_hi     ;set to 080h
             ldy #0
             ldx temp2_lo
             sta 08200h,x

dl_loop4:    lda (temp1),y 
             jsr send_byte
             iny
             bne dl_loop4
             inc temp1_hi
             bne dl_loop4
             inc temp2_lo
             dec temp2_hi
             bne dl_loop3

             lda #00h
             jsr send_byte
             lda #00h
             jsr send_byte
             lda #00h
             jsr send_byte
             rts



             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
