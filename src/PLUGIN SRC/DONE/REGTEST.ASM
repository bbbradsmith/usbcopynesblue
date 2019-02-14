             .title        "Bankwatch(tm)"

;Keeping an eye on data
;01/11/04 
;Written by KH
;Version 1.2
;modded to test VRC7 registers
;
;02/14/2019
;BS added chip reset / phase lock option
             
             ;vectors for standard system calls

send_byte:   .equ 0200h
baton:       .equ 0203h
chk_vram:    .equ 0206h
chk_wram:    .equ 0209h
wr_ppu:      .equ 020ch
read_byte:   .equ 020fh
init_crc:    .equ 0212h
do_crc:      .equ 0215h
finish_crc:  .equ 0218h

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

temp4:       .equ 00e6h   ;for wr_bank
temp4_lo:    .equ 00e6h
temp4_hi:    .equ 00e7h
temp5:       .equ 00e8h
temp5_lo:    .equ 00e8h
temp5_hi:    .equ 00e9h
x_temp:      .equ 00eah
y_temp:      .equ 00ebh

temp_crc:    .equ 00ech

port:        .equ 04a00h

;Bankwatch(tm) host plugin
;

             ;plugin header that describes what it does
             
             .org 0380h
             
             .db "VRC7 tester thingus" 
             .db 0

             .fill 0400h-*,00h    ;all plugins must reside at 400h

             lda #001h
             sta temp2_lo
             jsr reset_vrc7

main:        jsr set_in
             ; 55,AA = play note
             ; 44,BB = reset chip (also resets LFO phase)
             jsr read_byte
             cmp #055h
             beq main55
             cmp #044h
             bne main
             jmp phaselock
main55:      jsr read_byte
             cmp #0aah
             bne main
             
             lda #000h
             sta 09010h
             jsr read_byte
             jsr writewait
             lda #001h
             sta 09010h
             jsr read_byte
             jsr writewait
             lda #002h
             sta 09010h
             jsr read_byte
             jsr writewait
             lda #003h
             sta 09010h
             jsr read_byte
             jsr writewait
             lda #004h
             sta 09010h
             jsr read_byte
             jsr writewait
             lda #005h
             sta 09010h
             jsr read_byte
             jsr writewait
             lda #006h
             sta 09010h
             jsr read_byte
             jsr writewait
             lda #007h
             sta 09010h
             jsr read_byte
             jsr writewait       ;write 8 bytes to the custom instrument


             lda #010h
             sta 09010h
             lda #080h
             jsr writewait
             lda #011h
             sta 09010h
             lda #080h
             jsr writewait      ;lower 8 bits of freq

             jsr read_byte
             cmp #0ffh
             bne blahblah
             jmp main
             
blahblah:    asl a
             asl a
             asl a
             asl a
             sta temp1_lo
             
             lda #030h
             sta 09010h
             lda #00h           ;custom instrument
             jsr writewait
             lda #031h
             sta 09010h         ;non custom
             lda temp1_lo
             jsr writewait      ;instrument/volume

             jsr read_byte
             sta temp1_hi
             asl a
             and #0eh
             sta temp1_lo       ;read octave/chan info
             
             lda #020h
             sta 09010h
             lda temp1_lo
             jsr writewait
             lda #021h
             sta 09010h
             lda temp1_lo
             jsr writewait      ;lower 8 bits of freq

             lda #010h
             ora temp1_lo
             sta temp1_lo       ;set trigger bit
             
             
             lda #080h
             and temp1_hi
             beq no_cust

             lda #020h
             sta 09010h
             lda temp1_lo
             jsr writewait
             
no_cust:     lda #040h
             and temp1_hi
             beq no_cust2

             lda #021h
             sta 09010h
             lda temp1_lo
             jsr writewait      ;lower 8 bits of freq

no_cust2:    jmp main


writewait:   nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             sta 09030h
wait60:      nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             nop
             rts

             
set_in:      lda #00h
             sta port+03h
             rts

phaselock:   jsr read_byte
             cmp #0bbh
             bne plock_skip
             jsr reset_vrc7
plock_skip:  jmp main

reset_vrc7:  lda #040h
             sta 0E000h
             jsr wait60
             lda #000h
             sta 0E000h
             jsr wait60
             rts

             .fill 0800h-*,0ffh
             .end
