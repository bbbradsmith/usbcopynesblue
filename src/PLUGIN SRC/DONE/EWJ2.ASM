             .title        "H2288 Reader Plugin"


;06/11/00 
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

;Board: H2288
;Cart: Earth Worm Jim 2
;
;Note: mapper plugin stolen from TxROM
;
;This cart is somewhat similar to the MMC3.  8000h is used as a "control"
;register while 8001h is the "bank" register.
;
;Writing to 8000/8001h works just like it does on the MMC3, however the
;control words are different.
;
;8000:
;
;7       0
;---------
;SPxx xCCC
;
;S - Swap 0000-0fffh/1000-1fffh in PPU space.  If set, the upper and lower
;    4K blocks are swapped, including banking action.
;
;C - control word.  Writing here selects a control word.
;
;  0 - Swap 2K of CHR ROM at 0000h in PPU space
;  1 - Swap 1K of CHR ROM at 1400h in PPU space
;  2 - Swap 2K of CHR ROM at 0800h in PPU space
;  3 - Swap 1K of CHR ROM at 1c00h in PPU space
;  4 - Swap 8K of PRG ROM at 8000h in CPU space
;  5 - Swap 8K of PRG ROM at a000h in CPU space
;  6 - Swap 1K of CHR ROM at 1000h in PPU space
;  7 - Swap 1K of CHR ROM at 1800h in PPU space
;
;P - Swap PRG banks at 8000h/C000h
;
;Normally, the last two banks of the address space (c000-ffffh) are 
;mapped to the last two banks of the ROM.  However, when the P bit is
;set, 8K banks at 8000h and c000h are swapped.  This means 8000h holds
;the second to the last bank of ROM, and c000h will take on the current bank
;selected (which was at 8000h).
;
;Interrupts are used, but appear to be very similar to the MMC3 in that
;respect.
;
;A000
;
;7       0
;---------
;xxxx xxxM
;
;M - mirroring.  0 = 5, 1 = 3
;
;
;This cart contained a special form of "copy protection" on it to try and
;hamper emulation/running of the game.  This consists of using open bus
;and some extensive mapper tricks to do a very insanely complicated
;routine that comes down to a checksum/encryption.
;
;
;Anyways, it also uses a register at 5800h 
;
;There is a register mapped in at 5801h also, but it's not used.
;Decode this register at 5800,5802,5804,5806... 5ffeh since they make
;extensive use of the mirrors.
;
;bits:
;
;7       0
;---------
;xMAx BCZS
;
;
;M - mode.  when 0, allows the MMC3 to control PRG banking.
;           when 1, allows 5800h to control PRG banking.
;
;
;Z - bank size.  When 0, 8000-BFFF and C000-FFFF contain the same 16K
;                bank. (see below)
                 When 1, 8000-FFFF contains a single 32K PRG bank.
;
;S - 16K sub-bank.  When in 16K mode, this controls which 16K bank is
;                selected.
;
;ACB - these are the 32K PRG bank select bits (note order!!)
;
;A = upper bit, C = middle bit, and B = lower bit.  These three bits
;select a 32K bank, for a total of 256K of selectable bankage.
;
;
;

             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "TEROM, "
             .db "TFROM, TGROM, TKROM," 
             .db " TLROM, TSROM\n\r" 
             .db "32K-512K PRG, "
             .db "32K-256K CHR\n\r",0

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             lda #00h
             sta 0a000h

             ldx #02fh
             
ddloop:      txa
             jsr wr_ppu
             lda #0
             sta 2007h
             dex
             cpx #01fh
             bne ddloop   ;load first byte of 2000, 2400, 2800, 2c00 w/ 00h
             ldx #0       ;H mirroring
             lda #020h
             jsr wr_ppu
             lda #055h
             sta 2007h
             lda #028h
             jsr wr_ppu
             lda 2007h
             lda 2007h
             cmp #055h
             beq mirrord
             inx          ;V mirroring
             lda #024h
             jsr wr_ppu
             lda 2007h
             lda 2007h
             cmp #055h
             beq mirrord
             inx          ;4 screen
             bne got_mir
             
mirrord:     lda #01h
             sta 0a000h
             lda #024h
             jsr wr_ppu
             lda 2007h
             lda 2007h
             cmp #055h
             bne got_mir
             lda #00h
             sta 0a000h
             lda #028h
             jsr wr_ppu
             lda 2007h
             lda 2007h
             cmp #055h
             bne got_mir  ;test for MMC3 mirror control
             ldx #04h

got_mir:     txa
             jsr send_byte
             
             lda #1
             sta romsiz
             ldy #004h
             jsr comp_bank
             beq gotit
             asl romsiz
             ldy #008h
             jsr comp_bank
             beq gotit
             asl romsiz
             ldy #010h
             jsr comp_bank
             beq gotit
             asl romsiz
             ldy #020h
             jsr comp_bank
             beq gotit
             asl romsiz

gotit:       lsr romsiz
             php
             lda #0
             ror a
             sta temp3_hi
             jsr send_byte
             lda romsiz
             jsr send_byte
             lda romsiz
             plp
             rol a
             asl a
             asl a
             sta temp3_lo    ;# 8K banks
             lda #01h
             jsr send_byte

send_plp:    lda #4              ;was 6
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
             

;read CHR stuff             
;try VRAM
             lda #01h
             sta 0a000h   ;I don't know why, but it doesn't work without this
             
             lda #86h     ; was 82h
             sta 08000h
             lda #00h
             sta 08001h

             jsr chk_vram
             bne no_ram3
             jmp no_chr
             
             
no_ram3:     lda #1
             sta romsiz
             ldy #020h
             jsr comp_bank2
             beq gotit2
             asl romsiz
             ldy #040h
             jsr comp_bank2
             beq gotit2
             asl romsiz
             ldy #080h
             jsr comp_bank2
             beq gotit2
             asl romsiz
             
gotit2:      lda romsiz
             pha
             lsr romsiz
             lda #0
             sta temp3_hi    ;start out at 0
             ror a
             jsr send_byte
             lda romsiz
             jsr send_byte
             lda #02h
             jsr send_byte
             pla
             asl a
             asl a
             asl a
             asl a
             asl a  ;1,2,4,8 == 20,40,80,00
             sta temp3_lo

send_plp3:   lda #086h      ; was 82h
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
             
;check for save-game RAM and back it up if it exists             

no_chr:      lda #080h
             sta 0a001h
             
             jsr chk_wram
             bne no_ram2
             lda #020h
             tax
             jsr send_byte
             lda #0
             jsr send_byte
             lda #3
             jsr send_byte
             lda #0
             sta temp1_lo
             tay
             lda #060h
             sta temp1_hi
            
sr_lp:       lda (temp1),y
             jsr send_byte
             iny
             bne sr_lp
             inc temp1_hi
             jsr baton
             dex
             bne sr_lp
             lda #000h
             sta 0a001h
             

no_ram2:     lda #0
             jsr send_byte
             lda #0
             jsr send_byte
             lda #0
             jsr send_byte

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
             lda #004h       ;was 6h
             sta 08000h
             lda temp3_lo
             sta 08001h
             lda #005h       ;was 7h
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

cc_loop:     lda #086h       ;was 82h
             sta 08000h
             lda temp3_lo
             sta 08001h
             lda #081h       ;was 83h
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
