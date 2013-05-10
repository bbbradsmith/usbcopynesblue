             .title            "1M in 1 Reader"


;10/29/2000
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
             

             .db "For 1000000 in 1"
             .db " Multi"
             
             .fill 0400h-*,00h    ;all plugins must reside at 400h



got_mir:     lda #04h
             jsr send_byte
             

             lda #000h
             jsr send_byte
             lda #008h
             jsr send_byte
             lda #001h
             jsr send_byte

             lda #00h
             sta romsiz
             
gotit:       lda romsiz
             lsr a
             lsr a
             lsr a
             lsr a
             and #002h
             sta 06001h    ;set 256K bank
             lda #006h
             sta 08000h
             lda romsiz
             sta 08001h    ;set 8K bank
             ldx #020h
             ldy #000h
             sty temp1_lo
             lda #080h
             sta temp1_hi

send_plp:    lda (temp1),y         
             jsr send_byte
             iny
             bne send_plp
             inc temp1_hi
             dex
             bne send_plp
             inc romsiz
             lda romsiz
             cmp #040h
             bne gotit
             
             lda #0
             jsr send_byte
             lda #08h
             jsr send_byte
             lda #02h       ;512K CHR
             jsr send_byte
             
             lda #000h
             sta 06001h
             jsr dump_chr
             lda #020h
             sta 06001h
             jmp dump_chr


no_ram2:     lda #0
             jsr send_byte
             lda #0
             jsr send_byte
             lda #0
             jsr send_byte

             
             rts


dump_chr:    lda #8h
             sta romsiz

gotit2:      lda romsiz
             pha
             lsr romsiz
             lda #0
             sta temp3_hi    ;start out at 0
             pla
             asl a
             asl a
             asl a
             asl a
             asl a  ;1,2,4,8 == 20,40,80,00
             sta temp3_lo

send_plp3:   lda #082h
             sta 08000h
             lda temp3_hi
             sta 08001h      ;current bank
             lda #00h
             jsr wr_ppu
             lda 2007h      ;set up PPU
             ldy #0
             ldx #4

send_plp4:   lda 2007h
             jsr send_byte
             iny
             bne send_plp4
             jsr baton
             dex
             bne send_plp4
             inc temp3_hi
             dec temp3_lo
             bne send_plp3

             rts



             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
