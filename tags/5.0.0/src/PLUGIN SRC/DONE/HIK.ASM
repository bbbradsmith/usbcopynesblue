             .title        "HiK 4-in-1 Reader Plugin"


;06/10/00 
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


;Board name: 830821C
;Cart: 1994 SUPER HIK 4 in 1
;512K PRG ROM, 8K VRAM 
;
;Appears to be an extention of UNROM to allow for ease of piracy :-)
;
;This cart uses the address written to to select main banks and modes.
;it uses the data to select a PRG bank.
;
;Address bits:        Data bits:
;
;15                0  7       0
;-------------------  ---------
;1xLx xxxx DPPx xxMS  xxxx xppB
;
;Together, they form a 24 bit word
;
;P = 128K PRG ROM banks.  There are 4
;
;these operate on a single 128K sub-bank:
;p = 32K PRG ROM banks
;B = 16K bank (For 16K mode)
;
;S = size. if 1, 32K. "B" is not used and only the "p" bits are used.
;          if 0, 16K. "ppB" form a 3 bit word used to select a 16K bank.
;D = last bank enable.  When 0, the last 16K of the 32K PRG space is fixed
;          to the last 16K of the currently selected 128K PRG bank.
;
;M = mirroring.  0 = 5, 1 = 3
;
;L = lock.  If a "1" is written here, no further writes will change the 
;          "D", "P", "M", or "S" bits until the NES is reset or the power
;           is cycled!
;           If a "0" is written here, nothing happens and further writes
;           are possible.
;
;Note that once the mapper is "locked", writes will only affect the 16K/32K
;PRG bank... The cart is locked into a single NROM, BNROM or UNROM mode 
;this way and accepts writes to 8000-ffffh to select a 16K (or 32K) PRG bank.
;
;


             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "NROM -- 16K and 32K" 
             .db " carts w/ 8K CHR ROM",0

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             
;check mirroring             


             lda #04h
             jsr send_byte   ;send byte
             
             lda #000h
             jsr send_byte
             lda #008h       ;send size (512K)
             jsr send_byte
             lda #001h
             jsr send_byte   ;send PRG 
             
             lda #080h
             sta temp3_hi
             lda #00h
             sta temp3_lo    ;pop loc
             
             
             ldy #0
             sty temp1_lo
             sty temp2_hi
             lda #020h
             sta temp2_lo
             

dump_it2:    lda temp2_hi
             asl a
             asl a
             and #060h
             tax
             lda temp2_hi
             and #07h
             sta 08000h,x   ;select a PRG bank             
             lda #080h
             sta temp1_hi

dump_it:     lda (temp1),y
             jsr send_byte
             iny
             bne dump_it
             inc temp1_hi
             lda temp1_hi
             cmp #0c0h
             bne dump_it     ;do 32K bank
             inc temp2_hi
             dec temp2_lo
             bne dump_it2    ;do 128K bank
             
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             rts            ;done 


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
