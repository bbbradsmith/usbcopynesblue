             .title          "nsf log player"


;7/08/2013 
;Written by rainwarrior
;based on template by kevtris
;Version 1.0
             

             ;vectors for standard system calls

port:        .equ 04800h

send_byte:   .equ 0200h
baton:       .equ 0203h
chk_vram:    .equ 0206h
chk_wram:    .equ 0209h
wr_ppu:      .equ 020ch
read_byte:   .equ 020fh
init_crc:    .equ 0212h
do_crc:      .equ 0215h
finish_crc:  .equ 0218h

inbase:      .equ 01f0h

crc0:        .equ 0080h
crc1:        .equ 0081h
crc2:        .equ 0082h
crc3:        .equ 0083h

temp1:       .equ 00e0h
temp1_lo:    .equ 00e0h
temp1_hi:    .equ 00e1h
temp2:       .equ 00e2h
temp2_lo:    .equ 00e2h
temp2_hi:    .equ 00e3h
temp3:       .equ 00e4h
temp3_lo:    .equ 00e4h
temp3_hi:    .equ 00e5h


in_mode:    .equ 0304bh

            ;plugin header that describes what it does
            
            .org 0380h
            
            .db "NSF Log Player" 
            .db " (any)"
            .db 0

            .fill 0400h-*,00h    ;all plugins must reside at 400h

            lda #0
            sta 02000
            sta 02001
            sta 04803h        ;set to input mode

            ; timer setup borrowed from RDUMP1.ASM
            lda #085h
            sta port+04h
            lda #074h
            sta port+05h  ;timer value
            lda #040h
            sta port+0bh  ;timer interrupts continuous
            sta port+0eh  ;enable interrupts 

; Data stream:
;   $02 = VRC7 register delay
;   $01 = wait for next vblank
;   $ab $cd $ef = write $ef to $abcd

read_loop:  jsr read_byte
            ; VRC7 delay   ;No need for this.  jsr read_byte takes at least 52 cycles
;            cmp #02h       ;to complete. :) writes to 9030 only need at least 42 cycles
;            bne no_delay   ;of delay. The next time 9010/9030 gets writeen will be 6 read_bytes later. :)
;            stx 082h ; $82 was just the ZP address used by lagrange point for this
;            ldx #08h
;delay_loop: dex
;            bne delay_loop
;            ldx 082h
;            jmp read_loop
no_delay:   cmp #01h
            bne do_write
            ; wait for next vblank
;            lda #02h
;wait_vbl:   sta 04017h ; OAM DMA to kill time / reduce probability of 2002 conflict
;            bit 02002h
;            bpl wait_vbl
            ; timer code borrowed from RDUMP1.ASM, more reliable than $2002?
wait_vbl:   bit port+0dh
            bvc wait_vbl     ;wait for timer 1
            lda port+04h
            ; end of borrowed timer code
            jmp read_loop
            ; write data to register
do_write:   sta 01h ; zp 00,01 used for write address
            jsr read_byte
            sta 00h
            jsr read_byte
            ldy #0
            sta (00h), y
            jmp read_loop

            .fill 0800h-*,0ffh   ;fill rest to get 1K of data
            .end
