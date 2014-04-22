             .title         "UNROM512 Flasher"


;04/19/13
;Flasher for UNROM512
;Modified by DG
;2/15/07
;Modified by BP
;Version 1.0
;ORIGINAL SOURCE:
;03/05/06
;Written by KH
;Version 1.0
             
             ;vectors for standard system calls

send_byte:   .equ 0200h
baton:       .equ 0203h
chk_vram:    .equ 0206h
chk_wram:    .equ 0209h
read_byte:   .equ 020fh
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
currbank:    .equ 00e8h

             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "UNROM512 Flasher"

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             lda #0f0h
             sta 08000h       ;reset flash ROM
             
             jsr read_byte
             sta temp3+1      ;receive number of sectors to erase
             
             
             
             
             lda #0
             sta romsiz
             sta currbank
             sta temp1+0
             
             jsr softwareid
             sta temp3+1
             jsr send_byte
             lda temp3+1
             cmp #000h
             bne er_start
             
             txa             ;Unrecognized flash chip. Lets not erase it to be on the safe side.
             jsr send_byte
             tya
             jsr send_byte
             rts
             
er_start:    jsr read_byte	;Wait for confirmation to start.
             jsr eraseflash
             jsr send_byte

             lda #0
             sta currbank
             
prog1:       ldx currbank
             jsr selbank      ;select desired bank
             lda #080h
             sta temp1+1
             lda #000h
             sta temp1+0      ;start of bank to program
             
prog2:       jsr read_byte
             sta temp2
             ldy #000h
             jsr dobyte
             inc temp1+0
             bne prog2
             inc temp1+1
             lda #0c0h
             cmp temp1+1
             bne prog2        ;program all 16K
             inc currbank
             dec temp3+1
             bne prog1
             
             lda romsiz
             jsr send_byte
             rts
             
             

;temp1 = address, acc =data
dobyte:      
             ldx #001h
             jsr selbank
             ldx #$AA 
             stx $9555      ;5555 = $AA


             ldx #000h
             jsr selbank
             ldx #$55 
             stx $AAAA      ;2AAA = $55
 
             ldx #001h
             jsr selbank
             ldx #$A0 
             stx $9555      ;5555 = $A0

             ldx currbank
             jsr selbank
             lda temp2
             sta (temp1),y    ;byte to program


wtloop3:     lda (temp1),y
             cmp (temp1),y
             bne wtloop3   ;check toggle
             cmp temp2
             beq wr_success
             lda #0F0h
             sta romsiz
wr_success:  rts
             
softwareid:  
             ldx #001h
             jsr selbank
             lda #0aah    ;erase sector command
             sta 09555h  ;write to 5555

             ldx #000h
             jsr selbank
             lda #055h
             sta 0Aaaah  ;write to 2AAA
             
              ldx #001h
             jsr selbank
             lda #090h
             sta 09555h
             
             lda 08001h
             tay
             lda 08000h
             
             ldx #0F0h
             stx 08000h
             tax
             
             cmp #0BFh
             bne ret_zero
             tya
             cmp #0B5h
             beq ret_8
             cmp #0B6h
             beq ret_16
             cmp #0B7h
             beq ret_32
ret_zero:    lda #000h
             rts
ret_8:       lda #008h
             rts
ret_16:      lda #010h
             rts
ret_32:      lda #020h
             rts

eraseflash:       
             ldx #001h
             jsr selbank
             lda #0aah    ;erase sector command
             sta 09555h  ;write to 5555

             ldx #000h
             jsr selbank
             lda #055h
             sta 0Aaaah  ;write to 2AAA
             
              ldx #001h
             jsr selbank
            lda #080h
             sta 09555h  ;write to 5555

             ldx #001h
             jsr selbank
             lda #0aah
             sta 09555h   ;write to 5555

             ldx #000h
             jsr selbank
             lda #055h
             sta 0Aaaah   ;write to 2AAA

             ldx #001h
             jsr selbank
             lda #010h
             sta 09555h
             
wtloop:      lda 09555h
             cmp 09555h
             bne wtloop
             lda 09555h
             cmp 09555h
             bne wtloop
             lda 09555h
             cmp #0FFh
             beq er_success
             lda #0FFh
             rts
er_success:  lda temp3+1
             rts


selbank:     stx 0c000h
             rts


             .fill 0800h-*,0ffh   ;fill rest to get 1K of data

             .end
