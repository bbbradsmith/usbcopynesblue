             .title        "63 in 1 Reader Plugin"


;02/18/01 
;Written by KH
;Version 1.0
             
             ;vectors for standard system calls

send_byte:   .equ 0200h
baton:       .equ 0203h
wr_ppu:      .equ 020ch

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
             
             .db "63 in 1"

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             
             lda #04h
             jsr send_byte   ;send byte
             
             lda #00h
             sta temp2_lo
             sta temp2_hi

             lda #000h
             jsr send_byte
             lda #018h       ;send size
             jsr send_byte
             lda #001h
             jsr send_byte   ;send PRG 
             
di_2:        ldy #0
             sty temp1_lo
             lda #080h
             sta temp1_hi
             lda temp2_lo
             asl a
             ldx temp2_hi
             ora table1,x
             sta 08000h
             lda table2,x
             sta 08001h
             
dump_it:     lda (temp1),y
             jsr send_byte
             iny
             bne dump_it
             inc temp1_hi
             bne dump_it
             inc temp2_lo
             lda temp2_lo
             cmp #010h
             bne di_2
             lda #000h
             sta temp2_lo
             inc temp2_hi
             lda temp2_hi
             cmp #03h
             bne di_2

             
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             rts            ;done 

table1:      .db 000h,000h,080h
table2:      .db 000h,001h,001h


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data
             
             .db "P00800"
             .db "P20800"
             .db "P30800"
             
             .end
