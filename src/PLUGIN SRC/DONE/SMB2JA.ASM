             .title        "SMB2jA Reader Plugin"


;12/08/00 
;Written by KH
;Version 1.0
             
             ;vectors for standard system calls

send_byte:   .equ 0200h
baton:       .equ 0203h
chk_vram:    .equ 0206h
chk_wram:    .equ 0209h
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
temp4:       .equ 00e6h
romsiz:      .equ 00e7h
curr_bank:   .equ 00e8h

             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "Pirate SMB2jA plugin. "
             .db "128K PRG"

             .fill 0400h-*,00h    ;all plugins must reside at 400h
             
;check mirroring             

             
             
             ldx #00h
             
             lda #020h
             jsr wr_ppu
             lda #055h
             sta 2007h
             lda #0aah
             sta 2007h
             lda #024h
             jsr wr_ppu
             lda 2007h
             lda 2007h
             cmp #055h
             bne horz_mir
             lda 2007h
             cmp #0aah
             bne horz_mir
             lda #020h
             jsr wr_ppu
             lda #0aah
             sta 2007h
             lda #024h
             jsr wr_ppu
             lda 2007h
             lda 2007h
             cmp #0aah
             bne horz_mir
             inx

horz_mir:    txa
             jsr send_byte   ;send byte
             
             
             
; 001h game 0            
; 041h game 1
; 081h game 2
; 0C1h game 3
             
;4020h

;DACB
;6021

             lda #000h
             jsr send_byte
             lda #002h
             jsr send_byte
             lda #001h
             jsr send_byte
             
             ldx #000h
             
dd_lp:       jsr send_prg
             inx
             cpx #010h
             bne dd_lp

             lda #000h
             jsr send_byte
             lda #000h
             jsr send_byte
             lda #000h
             jsr send_byte
             rts

ddcs:        .db 000h,002h,004h,006h,001h,003h,005h,007h
             .db 008h,00ah,00ch,00eh,009h,00bh,00dh,00fh

send_prg:    lda #00h
             sta temp1+0
             tay
             lda #0c0h
             sta temp1+1    ;c000h

sp_lp:       lda ddcs,x
             sta 04020h
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             lda (temp1),y
             jsr send_byte
             iny
             bne sp_lp
             inc temp1+1
             lda temp1+1
             cmp #0e0h
             bne sp_lp
             rts


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
