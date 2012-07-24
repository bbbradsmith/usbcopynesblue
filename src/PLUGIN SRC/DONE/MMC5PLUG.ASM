temp1:       .equ $E0
temp1_lo:    .equ $E0
temp1_hi:    .equ $E1

temp2:       .equ $E2
temp2_lo:    .equ $E2
temp2_hi:    .equ $E3

temp3:       .equ $E4
temp3_lo:    .equ $E4
temp3_hi:    .equ $E5

temp4:       .equ $E6
temp4_lo:    .equ $E6
temp4_hi:    .equ $E7

temp5:       .equ $E8
temp5_lo:    .equ $E8
temp5_hi:    .equ $E9

x_temp:      .equ $EA

y_temp:      .equ $EB

temp_crc:    .equ $EC

.org $0380

.db "MMC5 Vertical Split"
.db " Mode Test",0

.fill $0400-*,$00			;all plugins must reside at $0400

plugin_start:	SEI
		CLD
		LDA #$00
		STA $2001
		STA $2000		;kill PPU
		LDX #$02		;wait 2 frames
ppuinit:	JSR waitvblank
		DEX
		BNE ppuinit
		DEX
		TXS

		LDA #$AA
		STA $5105		;init ExRAM
		LDA #$40
		STA temp1
		LDA #$55
		STA temp2
		JSR init_vram

		LDA #$00
		STA $5105		;init normal nametable
		LDA #$00
		STA temp1
		STA temp2
		JSR init_vram

		LDX #$00
clear_spr:	STX $2003
		STA $2004
		INX
		BNE clear_spr		;clear sprites

		LDA $2002
		LDX #$3F
		STX $2006
		LDX #$00
		STX $2006
		LDX #$00
set_pal:	TXA
		AND #$07
		STA $2007
		INX
		CPX #$10
		BNE set_pal
		LDX #$3F
		STX $2006
		LDX #$00
		STX $2006
		STX $2007

		LDA #$03
		STA $5101		;1kb CHR banks for background
		LDX #$03
init_chr:	TXA
		STA $5120,x
		STA $5124,x
		STA $5128,x		;init CHR banks
		DEX
		BMI init_chr

		LDA #$00
		STA $5104

		LDA #$88
		STA $5200		;left 1/4 screen is splitmode
		LDA #$FF
		STA x_temp
		STA y_temp		;clear Splitmode scroll
		LDA #$01
		STA $5202		;set CHR banks for split side

		LDA #$00
		STA $4015		;kill sound
                LDA #$C0
                STA $4017               ;disable frame IRQs
		LDA #$1E
		STA $2001		;enable sprites+bg
;		CLI			;don't re-enable interrupts in plugin
		JMP start_tests		;let the tests begin

waitvblank:	LDA $2002
		BPL waitvblank
		RTS

init_vram:	LDA $2002		;init VRAM
		LDX #$20
		STX $2006
		LDY #$00
		STY $2006
		LDY temp1
vramloop:	STY $2007
		INY
		CPY temp1
		BNE vramloop
		INX
		CPX #$24		;init $2000-$23FF
		BNE vramloop

		DEX
		STX $2006
		LDX #$C0
		STX $2006
		LDA temp2
attribloop:	STA $2007
		INX
		BNE attribloop		;clear attribute table
		RTS

start_tests:	JSR waitvblank

		LDX $2002
		LDX #$00
		STX $2006
		STX $2006
		STX $2005
		STX $2005

		CLC
		LDX temp3
		INX
		TXA
		AND #$01
		TAX
		STA temp3
		BNE setscroll

		LDA x_temp
		ADC #$01
		STA x_temp
		LDA y_temp
		ADC #$00
		STA y_temp

setscroll:	LDA x_temp
		STA $5201
		LDA y_temp
		STA $5201
		JMP start_tests

.fill $0800-*,$00			;1kb space for plugin
.end
