#include "StdAfx.h"
#define	CMD_NAME	"Disassemble"

enum ADDRMODE { IMP, ACC, IMM, ADR, ABS, IND, REL, ABX, ABY, ZPG, ZPX, ZPY, INX, INY, ERR, NUM_ADDR_MODES };

enum ADDRMODE TraceAddrMode[256] =
{
	IMM,INX,ERR,INX,ZPG,ZPG,ZPG,ZPG,IMP,IMM,ACC,IMM,ABS,ABS,ABS,ABS,REL,INY,ERR,INY,ZPX,ZPX,ZPX,ZPX,IMP,ABY,IMP,ABY,ABX,ABX,ABX,ABX,
	ADR,INX,ERR,INX,ZPG,ZPG,ZPG,ZPG,IMP,IMM,ACC,IMM,ABS,ABS,ABS,ABS,REL,INY,ERR,INY,ZPX,ZPX,ZPX,ZPX,IMP,ABY,IMP,ABY,ABX,ABX,ABX,ABX,
	IMP,INX,ERR,INX,ZPG,ZPG,ZPG,ZPG,IMP,IMM,ACC,IMM,ADR,ABS,ABS,ABS,REL,INY,ERR,INY,ZPX,ZPX,ZPX,ZPX,IMP,ABY,IMP,ABY,ABX,ABX,ABX,ABX,
	IMP,INX,ERR,INX,ZPG,ZPG,ZPG,ZPG,IMP,IMM,ACC,IMM,IND,ABS,ABS,ABS,REL,INY,ERR,INY,ZPX,ZPX,ZPX,ZPX,IMP,ABY,IMP,ABY,ABX,ABX,ABX,ABX,
	IMM,INX,IMM,INX,ZPG,ZPG,ZPG,ZPG,IMP,IMM,IMP,IMM,ABS,ABS,ABS,ABS,REL,INY,ERR,INY,ZPX,ZPX,ZPY,ZPY,IMP,ABY,IMP,ABY,ABX,ABX,ABY,ABY,
	IMM,INX,IMM,INX,ZPG,ZPG,ZPG,ZPG,IMP,IMM,IMP,IMM,ABS,ABS,ABS,ABS,REL,INY,ERR,INY,ZPX,ZPX,ZPY,ZPY,IMP,ABY,IMP,ABY,ABX,ABX,ABY,ABY,
	IMM,INX,IMM,INX,ZPG,ZPG,ZPG,ZPG,IMP,IMM,IMP,IMM,ABS,ABS,ABS,ABS,REL,INY,ERR,INY,ZPX,ZPX,ZPX,ZPX,IMP,ABY,IMP,ABY,ABX,ABX,ABX,ABX,
	IMM,INX,IMM,INX,ZPG,ZPG,ZPG,ZPG,IMP,IMM,IMP,IMM,ABS,ABS,ABS,ABS,REL,INY,ERR,INY,ZPX,ZPX,ZPX,ZPX,IMP,ABY,IMP,ABY,ABX,ABX,ABX,ABX
};

unsigned char TraceAddrBytes[NUM_ADDR_MODES] = {1,1,2,3,3,3,2,3,3,2,2,2,2,2,1};

char TraceArr[256][5] =
{
	" BRK"," ORA","*HLT","*SLO","*NOP"," ORA"," ASL","*SLO"," PHP"," ORA"," ASL"," ???","*NOP"," ORA"," ASL","*SLO",
	" BPL"," ORA","*HLT","*SLO","*NOP"," ORA"," ASL","*SLO"," CLC"," ORA","*NOP","*SLO","*NOP"," ORA"," ASL","*SLO",
	" JSR"," AND","*HLT","*RLA"," BIT"," AND"," ROL","*RLA"," PLP"," AND"," ROL"," ???"," BIT"," AND"," ROL","*RLA",
	" BMI"," AND","*HLT","*RLA","*NOP"," AND"," ROL","*RLA"," SEC"," AND","*NOP","*RLA","*NOP"," AND"," ROL","*RLA",
	" RTI"," EOR","*HLT","*SRE","*NOP"," EOR"," LSR","*SRE"," PHA"," EOR"," LSR"," ???"," JMP"," EOR"," LSR","*SRE",
	" BVC"," EOR","*HLT","*SRE","*NOP"," EOR"," LSR","*SRE"," CLI"," EOR","*NOP","*SRE","*NOP"," EOR"," LSR","*SRE",
	" RTS"," ADC","*HLT","*RRA","*NOP"," ADC"," ROR","*RRA"," PLA"," ADC"," ROR"," ???"," JMP"," ADC"," ROR","*RRA",
	" BVS"," ADC","*HLT","*RRA","*NOP"," ADC"," ROR","*RRA"," SEI"," ADC","*NOP","*RRA","*NOP"," ADC"," ROR","*RRA",
	"*NOP"," STA","*NOP","*SAX"," STY"," STA"," STX","*SAX"," DEY","*NOP"," TXA"," ???"," STY"," STA"," STX","*SAX",
	" BCC"," STA","*HLT"," ???"," STY"," STA"," STX","*SAX"," TYA"," STA"," TXS"," ???"," ???"," STA"," ???"," ???",
	" LDY"," LDA"," LDX","*LAX"," LDY"," LDA"," LDX","*LAX"," TAY"," LDA"," TAX"," ???"," LDY"," LDA"," LDX","*LAX",
	" BCS"," LDA","*HLT","*LAX"," LDY"," LDA"," LDX","*LAX"," CLV"," LDA"," TSX"," ???"," LDY"," LDA"," LDX","*LAX",
	" CPY"," CMP","*NOP","*DCP"," CPY"," CMP"," DEC","*DCP"," INY"," CMP"," DEX"," ???"," CPY"," CMP"," DEC","*DCP",
	" BNE"," CMP","*HLT","*DCP","*NOP"," CMP"," DEC","*DCP"," CLD"," CMP","*NOP","*DCP","*NOP"," CMP"," DEC","*DCP",
	" CPX"," SBC","*NOP","*ISB"," CPX"," SBC"," INC","*ISB"," INX"," SBC"," NOP","*SBC"," CPX"," SBC"," INC","*ISB",
	" BEQ"," SBC","*HLT","*ISB","*NOP"," SBC"," INC","*ISB"," SED"," SBC","*NOP","*ISB","*NOP"," SBC"," INC","*ISB"
};

BOOL	CMD_DISASM (void)
{
	FILE *BIN, *ASM;
	char filename[MAX_PATH];
	int pc;
	BOOL badops;

	if (!PromptFile(topHWnd,"6502 Binary Data (*.*)\0*.*\0\0",filename,NULL,NULL,"Select code segment","*",FALSE))
		return FALSE;

	BIN = fopen(filename,"rb");
	if (!BIN)
	{
		MessageBox(topHWnd,"Failed to open file!",MSGBOX_TITLE,MB_OK | MB_ICONERROR);
		return FALSE;
	}

	pc = 0;	// using variable PC since we don't save this value
	PromptTitle = "File offset to begin disassembly from?\n(cancel for beginning of file)";
	if (Prompt(topHWnd))
		sscanf(PromptResult,"%i",&pc);
	fseek(BIN,pc,SEEK_SET);

	pc = 0x8000;
	PromptTitle = "Address of first instruction?\n(cancel for 0x8000)";
	if (Prompt(topHWnd))
		sscanf(PromptResult,"%i",&pc);

	if (!PromptFile(topHWnd,"Disassembly (*.ASM)\0*.asm\0\0",filename,NULL,NULL,"Enter filename for disassembly output","asm",TRUE))
		return FALSE;

	ASM = fopen(filename,"wb");
	if (!ASM)
	{
		fclose(BIN);
		MessageBox(topHWnd,"Failed to create output file!",MSGBOX_TITLE,MB_OK | MB_ICONERROR);
		return FALSE;
	}

	badops = (MessageBox(topHWnd,"Enable invalid opcodes?",MSGBOX_TITLE,MB_YESNO | MB_ICONQUESTION) == IDYES);

	while ((!feof(BIN)) && (pc < 0x10000))
	{
		unsigned char OpData[3] = {0,0,0};
		unsigned short Operand = 0;
		int AddrMode;
		char *Instruct;
		fread(OpData+0,1,1,BIN);

		AddrMode = TraceAddrMode[OpData[0]];
		Instruct = TraceArr[OpData[0]];

		if (!badops && Instruct[0] == '*')
		{
			AddrMode = ERR;
			Instruct = " ???";
		}
			
		switch (AddrMode)
		{
		case IND:	case ADR:	case ABS:	case ABX:	case ABY:
			fread(OpData+1,1,1,BIN);
			fread(OpData+2,1,1,BIN);
			Operand = OpData[1] | (OpData[2] << 8);
			break;
		case IMM:	case ZPG:	case ZPX:	case ZPY:	case INX:	case INY:
			fread(OpData+1,1,1,BIN);
			Operand = OpData[1];
			break;
		case IMP:	case ACC:	case ERR:
			break;
		case REL:
			fread(OpData+1,1,1,BIN);
			Operand = pc + 2 + (signed char)OpData[1];
			break;
		}

		switch (AddrMode)
		{
		case IMP:	fprintf(ASM,"%04X  %02X       %s\n",			pc,OpData[0],				Instruct);		break;
		case ERR:	fprintf(ASM,"%04X  %02X       %s\n",			pc,OpData[0],				Instruct);		break;
		case ACC:	fprintf(ASM,"%04X  %02X       %s A\n",			pc,OpData[0],				Instruct);		break;
		case IMM:	fprintf(ASM,"%04X  %02X %02X    %s #$%02X\n",		pc,OpData[0],OpData[1],			Instruct,Operand);	break;
		case REL:	fprintf(ASM,"%04X  %02X %02X    %s $%04X\n",		pc,OpData[0],OpData[1],			Instruct,Operand);	break;
		case ZPG:	fprintf(ASM,"%04X  %02X %02X    %s $%02X\n",		pc,OpData[0],OpData[1],			Instruct,Operand);	break;
		case ZPX:	fprintf(ASM,"%04X  %02X %02X    %s $%02X,X\n",		pc,OpData[0],OpData[1],			Instruct,Operand);	break;
		case ZPY:	fprintf(ASM,"%04X  %02X %02X    %s $%02X,Y\n",		pc,OpData[0],OpData[1],			Instruct,Operand);	break;
		case INX:	fprintf(ASM,"%04X  %02X %02X    %s ($%02X,X)\n",	pc,OpData[0],OpData[1],			Instruct,Operand);	break;
		case INY:	fprintf(ASM,"%04X  %02X %02X    %s ($%02X),Y\n",	pc,OpData[0],OpData[1],			Instruct,Operand);	break;
		case ADR:	fprintf(ASM,"%04X  %02X %02X %02X %s $%04X\n",		pc,OpData[0],OpData[1],OpData[2],	Instruct,Operand);	break;
		case ABS:	fprintf(ASM,"%04X  %02X %02X %02X %s $%04X\n",		pc,OpData[0],OpData[1],OpData[2],	Instruct,Operand);	break;
		case IND:	fprintf(ASM,"%04X  %02X %02X %02X %s ($%04X)\n",	pc,OpData[0],OpData[1],OpData[2],	Instruct,Operand);	break;
		case ABX:	fprintf(ASM,"%04X  %02X %02X %02X %s $%04X,X\n",	pc,OpData[0],OpData[1],OpData[2],	Instruct,Operand);	break;
		case ABY:	fprintf(ASM,"%04X  %02X %02X %02X %s $%04X,Y\n",	pc,OpData[0],OpData[1],OpData[2],	Instruct,Operand);	break;
		}
		pc += TraceAddrBytes[AddrMode];
	}
	fclose(BIN);
	fclose(ASM);
	return TRUE;
}