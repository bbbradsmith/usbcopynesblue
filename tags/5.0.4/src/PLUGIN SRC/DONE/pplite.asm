.title "PowerPak Lite Loader"

;2/15/2007
;Modified by BP
;Version 1.0

;ORIGINAL SOURCE
;2005/12/01
;Written by Quietust
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


.org $0380
.db "PowerPak Lite",0

.fill $0400-*,$00			;all plugins must reside at $0400

reset:	
  LDA #$00
	STA $4803	;input mode
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
  
  ;;;;;; set exp0 = 0
  lda $4800
  and #$f7
  sta $4800
             
  ;;;; set to mapper UROM 
  ;;;;;   7   6    5    4     3   2   1   0
  ;;;;;  a17 a16  a15  a14        mappernum
  lda #%11110010             ;;;urom = 2
  sta $6000  ;;write prg config to wram area
  lda #$00
  sta $6000  ;;write chr config to wram area


  ;;;; get max 256KB prg
  lda #$00
  sta currbank
  jsr read_byte
  sta temp3+1      ; # of 16K banks
             
progprg1:
  ldx currbank
  jsr selprgbank      ;select desired bank
  lda #$80
  sta temp1+1
  lda #$00
  sta temp1+0      ;start of bank to program
             
progprg2:       
  jsr read_byte
  ldy #$00
  sta (temp1),y     ;program byte to sram
  inc temp1+0
  bne progprg2
  inc temp1+1
  lda #$c0
  cmp temp1+1
  bne progprg2        ;program all 16K
  inc currbank
  dec temp3+1
  bne progprg1


  
  
  
  ;;;; set to mapper COLOR
  ;;;;;   7   6    5    4     3   2   1   0
  ;;;;;  a17 a16  a15  a14        mappernum
  lda #%00000101             ;;;colordreams=5
  sta $6000  ;;write prg config to wram area

  ;;;;;   7   6    5    4     3   2   1   0
  ;;;;;          cram  mir  a16 a15 a14 a13
  lda #%00101111
  sta $6000  ;;write chr config to wram area



  ;;;; get max 128KB chr
  lda #$00
  sta currbank
  jsr read_byte
  sta temp3+1      ; # of 8K banks
  beq config       ;if 0 chr banks

             
progchr1:
  ;;;; reset ppu pointer
  lda #$20
  sta temp1_lo
  lda #$00
  sta $2006
  sta $2006
  
  jsr selchrbank      ;select desired bank
  lda #$80
  sta temp1+1
  lda #$00
  sta temp1+0         ;start of bank to program
             
progchr2:       
  jsr read_byte
  sta $2007           ;program byte to sram
  inc temp1+0
  bne progchr2
  inc temp1+1
  lda #$A0
  cmp temp1+1
  bne progchr2        ;program all 8K
  inc currbank
  dec temp3+1
  bne progchr1




config:
  ;;;; get config byte
  ;;;; write config byte
  lda $4800
  and #$f7
  sta $4800     ;disable mapper, enable prg writing   exp0=0
  
  jsr read_byte
  sta $6000     ;put prg config byte into cpld

  jsr read_byte
  sta $6000     ;put chr config byte into cpld
  

;runwait1:
;	JSR read_byte
;	CMP #$55
;	BNE runwait1

;runwait2:
;	JSR read_byte
;	CMP #$AA
;	BNE runwait2

  lda $4800
  ora #$08
  sta $4800   ;enable the mapper, disable prg writing  exp0=1


  LDA #$FC 
  AND $4800
  STA $4800	;unmap BIOS
  JMP ($FFFC)	;and jump into game
;  rts






selprgbank:
  lda $4800
  ora #$08
  sta $4800   ;enable the mapper, disable prg writing  exp0=1
  
  stx $8000
  
  and #$f7
  sta $4800   ;disable mapper, enable prg writing   exp0=0
  rts


selchrbank:
  lda $4800
  ora #$08
  sta $4800   ;enable the mapper, disable prg writing  exp0=1
  
  ;;use d7-4
  lda currbank
  asl a
  asl a
  asl a
  asl a
  sta $8000
  
  lda $4800
  and #$f7
  sta $4800   ;disable mapper, enable prg writing   exp0=0
  rts






  .fill 0800h-*,0ffh   ;fill rest to get 1K of data

  .end
