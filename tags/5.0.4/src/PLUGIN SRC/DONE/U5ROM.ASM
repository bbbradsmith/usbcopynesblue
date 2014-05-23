             .title        "UNROM Reader Plugin"

;04/21/14
;Modified for detecting one-screen mirroring
;Modified for detecting CHR Ram size
;Modified for detecting if flashable
;Modification by DG
;05/02/13
;Modified for 512k oversized UxROM
;Modification by BS
;06/12/00 
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
temp4:       .equ 00e6h
temp4_lo:    .equ 00e6h
temp4_hi:    .equ 00e7h
temp5:       .equ 00e8h
temp5_lo:    .equ 00e8h
temp5_hi:    .equ 00e9h
x_temp:      .equ 00eah
y_temp:      .equ 00ebh
mapper30:    .equ 00ech
rom_size:    .equ 00edh

             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "UNROM512 -- 512K" 
             .db " carts w/ 8-32K VRAM",0

             .fill 0400h-*,00h    ;all plugins must reside at 400h
             
;check mirroring             
			 lda #08h      ;Assume the rom size is 512k. flash chip software ID will tell otherwise.
			 sta rom_size
             ldx #00h
             stx mapper30
             
             lda #0F0h
             sta 8000h    ;Flash chip reset command, assuming we are on a flash chip.
             
             lda #000h
             jsr wr_bank	;Set mapper controlled one-screen to screen A
             lda #020h
             jsr chk_ppu1
             lda #024h
             jsr chk_ppu2
             cmp #001h
             bne horz_mir
             
             lda #020h
             jsr chk_ppu3
             lda #024h
             jsr chk_ppu4
             cmp #001h
             bne horz_mir
             inx			;It is either vertical mirroring or mapper controlled one-screen mirroring.
             
             lda #020h
             jsr chk_ppu1
             lda #080h
             jsr wr_bank		;Set mapper controlled one-screen to screen B
             lda #020h
             jsr chk_ppu2
             cmp #001h
             bne one_scr
             lda #000h
             jsr wr_bank		;Set mapper controlled one-screen to screen A
             lda #020h
             jsr chk_ppu3
             lda #080h
             jsr wr_bank		;Set mapper controlled one-screen to screen B
             lda #020h
             jsr chk_ppu4
             cmp #001h
             beq horz_mir

one_scr:     inx			;Was mapper controlled mirroring
			 stx mapper30	;Onescreen mirroring control is emulated by mapper 30.
horz_mir:    txa			;Was either horizontal or vertical mirroring.
             jsr send_byte   ;send byte
             
             ;Now check if the board is self flashable.  (This is done without modifying it.)
             ldx #01Fh
next_bank:   lda #080h
             sta temp1_hi
             lda #000h
             sta temp1_lo
             txa
             jsr wr_bank
next_try:    ldy #000h
             lda (temp1),Y
             cmp #0BFh		;BF is the flash chip manufacturer ID. Therefore, we want to confirm we don't get
             bne flash_chk  ;a false positive, by not having the value already existing in this location.
             inc temp1_hi
             inc temp1_hi
             lda temp1_hi
             cmp #0c0h
             bne next_try
             dex
             bpl next_bank
             jmp skip_chk	;All 1024 locations happened to already contain the software ID check value.
                            ;As such, it is not possible to safely check if the chip is flashable non-destructively.
flash_chk:   stx x_temp
             lda #001h
             sta 0c000h
             lda #0aah
             sta 09555h
             lda #000h
             sta 0c000h
             lda #055h
             sta 0aaaah
             lda #001h
             sta 0c000h
             lda #090h
             sta 09555h
             lda x_temp
             sta 0c000h
             ldy #000h
             lda (temp1),Y
             cmp #0BFh
             bne unknwn_flsh
             iny
             lda (temp1),Y
             cmp #0B7h
             beq flash_found
             lsr rom_size
             cmp #0B6h
             beq flash_found
             lsr rom_size
             cmp #0B5h
             beq flash_found
             lda #008h
             sta rom_size
unknwn_flsh: lda #0F0h
             sta 08000h    ;Still do the exit software ID mode, just in case chip manufacturers were changed.
wait_loop2:  lda 08000h    ;since writing of this plugin. For the time being, we are going to assume the game
             cmp 08000h    ;isn't self flashable. (This can be checked for manually, by opening the cartridge.)
             bne wait_loop2
             jmp skip_chk

flash_found: lda #0F0h     ;We got software identification, we now need to exit that mode.
             sta 08000h    ;In addition, we also confirmed the rom size, by the chip ID.

wait_loop:   lda 08000h
             cmp 08000h
             bne wait_loop
             
             lda #000h
             jsr send_byte
             lda #000h
             jsr send_byte
             lda #003h
             sta mapper30
             jsr send_byte ;And tell the copynes client that the board is flashable.
             
             
             ;Now check chr ram size.
skip_chk     ldx #007h
             
             lda #000h
             jsr wr_bank	;Set chr ram bank 0
             lda #000h
             jsr chk_ppu1
             lda #020h
             jsr wr_bank	;Set chr ram bank 1
             lda #000h
             jsr chk_ppu2
             cmp #001h
             bne v16kchr
             lda #000h
             jsr wr_bank   ;Set chr ram bank 0
             lda #000h
             jsr chk_ppu3
             lda #020h
             jsr wr_bank   ;Set chr ram bank 1
             lda #000h
             jsr chk_ppu4
             cmp #001h
             beq v8kchr
             
v16kchr:     inx
             stx mapper30	;Mapper 30 emulates 8/16/32K chr ram. Mapper 2 only emulates 8K chr ram.
             
             lda #000h
             jsr chk_ppu1
             lda #060h
             jsr wr_bank   ;Set chr ram bank 3
             lda #000h
             jsr chk_ppu2
             cmp #001h
             bne v32kchr
             lda #020h
             jsr wr_bank   ;Set chr ram bank 1
             lda #000h
             jsr chk_ppu3
             lda #060h
             jsr wr_bank   ;Set chr ram bank 3
             lda #000h
             jsr chk_ppu4
             cmp #001h
             beq v8kchr
             
v32kchr:     inx
v8kchr:      lda mapper30
             beq next_part   ;At least one thing was different about this board, that is incompatible
             lda #0          ;with mapper 2.  As such, we have to communicate this fact back to the
             jsr send_byte   ;copynes client, so that it can adjust the mapper.
             txa
             jsr send_byte
             lda #005h       ;05 = Send battery wram size, wram_size, battery vram size, vram_size.
             jsr send_byte   ;This is a nes 2.0 specification
             
             lda #01Eh
             jsr send_byte
             lda #000h
             jsr send_byte
             lda #006h       ;06 = send mapper/submapper override. Byte 1 is mapper.
             jsr send_byte   ;Byte 2 is upper 4 mapper bits in low nibble, and submapper in high nibble.
                             ;Here, we are telling the client to use mapper 30, submapper 0, for building this .NES file.
             

next_part:   ldx rom_size
             lda #0
             jsr send_byte
             txa             ;send size
             jsr send_byte
             lda #001h
             jsr send_byte   ;send PRG 
             
             lda #0
             sta temp3_lo
             txa
             asl a
             asl a           ;8 or 16 banks
             sta temp3_hi
            
             
di_loop2:    lda temp3_lo
             jsr wr_bank
             ldx #040h
             ldy #0
             sty temp1_lo
             lda #080h
             sta temp1_hi

dump_it:     lda (temp1),y
             jsr send_byte
             iny
             bne dump_it
             jsr baton
             inc temp1_hi
             dex
             bne dump_it
             inc temp3_lo
             dec temp3_hi
             bne di_loop2
             
             lda #000h
             jsr send_byte
             lda #000h
             jsr send_byte
             lda #000h
             jsr send_byte  ;send end block
             rts
             
wr_bank:     stx x_temp
             sty y_temp
             sta temp4_lo   ;store desired bank
             lda #0
             sta temp5_lo
             lda #0c0h
             sta temp5_hi   ;start addr
             ldx #040h      ;# iterations
             ldy #0

wrb_loop:    lda (temp5),y
             and #1fh
             cmp temp4_lo   ;check current byte
             beq gotit
             iny
             bne wrb_loop
             inc temp5_hi
             bne wrb_loop   ;keep checking
             lda temp4_lo
             sta 0c000h
             ldx x_temp
             ldy y_temp
             rts            ;if it wasn't found, bag it
             
gotit:       lda (temp5),y             
             sta (temp5),y  ;if we found it, do the switch
             ldx x_temp
             ldy y_temp
             rts
             
chk_ppu1:    jsr wr_ppu
             lda #055h
             sta 2007h
             lda #0aah
             sta 2007h
             rts
             
chk_ppu2:    jsr wr_ppu
             lda 2007h
             lda 2007h
             cmp #055h
             bne ret_ppu_f
             lda 2007h
             cmp #0aah
             bne ret_ppu_f
             lda #001h
             rts
ret_ppu_f:   lda #000h
             rts
             
chk_ppu3:    jsr wr_ppu
             lda #0aah
             sta 2007h
             rts

chk_ppu4:    jsr wr_ppu
             lda 2007h
             lda 2007h
             cmp #0aah
             bne ret_ppu_f
             lda #001h
             rts


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
