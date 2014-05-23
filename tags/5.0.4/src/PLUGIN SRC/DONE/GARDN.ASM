             .title        "GAR RAM Reader Plugin"


;06/16/00 
;Written by KH
;Version 1.0
             
;protocol for reading:             
;
;send out size of PRG ROM (two bytes, LSB first) # of 256 byte pages
;indicate PRG ROM (01h = PRG)
;send out bytes for PRG
;send out size of CHR ROM (two bytes, LSB first) # of 256 byte pages
;indicate CHR ROM (02h = CHR)
;send out stop (00h)


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
             
             .db "GAR RAM reader" 
             .db 0

             .fill 0400h-*,00h    ;all plugins must reside at 400h





             ldx #008h
             ldy #0
             sty temp1_lo
             lda #050h
             sta temp1_hi

dump_it:     lda (temp1),y
             jsr send_byte
             iny
             bne dump_it
             jsr baton
             inc temp1_hi
             dex
             bne dump_it
             
             rts            ;done 


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
