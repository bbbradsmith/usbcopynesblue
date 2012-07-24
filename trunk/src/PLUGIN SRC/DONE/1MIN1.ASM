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
             

             lda #080h
             sta 0a001h
             lda #088h
             sta 06000h
             lda #03eh
             sta 06000h
             lda #00ah
             sta 06000h
             lda #0beh
             sta 06000h

             ldx #0
             lda #088h
             sta 06000h
             lda #03eh
             sta 06000h
             lda #07ah
             sta 06000h
             lda #0beh
             sta 06000h
             lda 0dfe0h
             cmp #0aah
             beq n1
             ldx #1
             
n1:          lda #088h
             sta 06000h
             lda #07eh
             sta 06000h
             lda #00ah
             sta 06000h
             lda #0beh
             sta 06000h
             lda 0dfe0h
             cmp #0aah
             beq n2
             ldx #2
             
n2:          lda #0f8h
             sta 06000h
             lda #0beh
             sta 06000h
             lda #00ah
             sta 06000h
             lda #0beh
             sta 06000h
             lda 0dfe0h
             cmp #0aah
             beq n3
             ldx #3

n3:          lda #088h
             sta 06000h
             lda #03eh
             sta 06000h
             lda #00ah
             sta 06000h
             lda #0beh
             sta 06000h
             
             
             
             nop
             nop
             nop
             nop
             
             
             
             ldx #0
             
bbs:         lda #000h
             sta 06000h
             lda #000h
             sta 06000h
             lda #00fh
             sta 06000h
             lda #080h
             sta 06000h
             dex
             bne bbs
             
;             lda #040h
;             sta 0a001h
             
             lda 0fffch
             lda 0fffdh

             
       ;      lda #1
       ;      sta romsiz
       ;      ldy #004h
       ;      jsr comp_bank
       ;      beq gotit
       ;      asl romsiz
       ;      ldy #008h
       ;      jsr comp_bank
       ;      beq gotit
       ;      asl romsiz
       ;      ldy #010h
       ;      jsr comp_bank
       ;      beq gotit
       ;      asl romsiz
       ;      ldy #020h
       ;      jsr comp_bank
       ;      beq gotit
       ;      asl romsiz

             lda #010h
             sta romsiz

gotit:       lsr romsiz
             lda #0
             ror a
             sta temp3_hi
             jsr send_byte
             lda romsiz
             jsr send_byte
             lda temp3_hi
             rol a
             lda romsiz
             rol a
             asl a
             asl a
             sta temp3_lo    ;# 8K banks
             lda #01h
             jsr send_byte

send_plp:    lda #6
             sta 08000h
             lda temp3_hi
             sta 08001h
             inc temp3_hi
             lda #0
             sta temp1_lo
             lda #080h
             sta temp1_hi
             ldx #020h
             ldy #0

send_plp2:   lda (temp1),y
             jsr send_byte
             iny
             bne send_plp2
             inc temp1_hi
             jsr baton
             dex
             bne send_plp2    ;send 8K bank
             dec temp3_lo
             bne send_plp
             
             
             
             lda #0
             jsr send_byte
             lda #08h
             jsr send_byte
             lda #02h       ;512K CHR
             jsr send_byte
             
             jsr dump_chr

             ldx #0
             
bbd:         lda #000h
             sta 06000h
             lda #000h
             sta 06000h
             lda #01fh
             sta 06000h
             lda #080h
             sta 06000h
             dex
             bne bbd


             jsr dump_chr




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

;y = bank to compare
;z=same
comp_bank:   ldx #0
             stx temp3_lo    ;lower pointer
             sty temp3_hi    ;upper pointer
             sty temp4       ;# blocks to compare

cb_loop:     lda #000h       ;init pointers
             sta temp1_lo
             sta temp2_lo
             lda #080h
             sta temp1_hi
             lda #0a0h
             sta temp2_hi    ;pointers 1,2 to 8000/a000
             lda #006h
             sta 08000h
             lda temp3_lo
             sta 08001h
             lda #007h
             sta 08000h
             lda temp3_hi
             sta 08001h      ;write in current banks
             ldx #020h
             ldy #0

cb_loop2:    lda (temp1),y
             cmp (temp2),y
             bne diff
             iny
             bne cb_loop2
             inc temp1_hi
             inc temp2_hi
             dex
             bne cb_loop2
             inc temp3_lo
             inc temp3_hi
             dec temp4
             bne cb_loop

diff:        rts

;y = bank to compare
;z=same
;for CHR
comp_bank2:  ldx #0
             stx temp3_lo    ;lower pointer
             sty temp3_hi    ;upper pointer
             sty temp4       ;# blocks to compare

cc_loop:     lda #082h
             sta 08000h
             lda temp3_lo
             sta 08001h
             lda #083h
             sta 08000h
             lda temp3_hi
             sta 08001h      ;write in current banks
             ldx #004h
             lda #000h
             sta curr_bank   ;reset current bank

cc_loop2:    ldy #0
             lda curr_bank
             sta 2006h       ;pointer =000h
             sty 2006h
             lda 2007h       ;garbage read

ql:          lda 2007h
             sta 0300h,y
             iny
             bne ql          ;load 256 bytes for testing
             lda curr_bank
             clc
             adc #4
             inc curr_bank
             sta 2006h       ;pointer =400h
             sty 2006h
             lda 2007h       ;garbage read

cc_loop3:    lda 2007h
             cmp 0300h,y
             bne diff2
             iny
             bne cc_loop3
             dex
             bne cc_loop2
             inc temp3_lo
             inc temp3_hi
             dec temp4
             bne cc_loop

diff2:       rts


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
