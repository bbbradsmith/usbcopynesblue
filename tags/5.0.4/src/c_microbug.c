#include "StdAfx.h"
#define	CMD_NAME	"MicroBug"

/*
Disassembly:
IDC_MICRO_DISASM - Listing
IDC_MICRO_DISPGUP - Up 1 Page
IDC_MICRO_DISUP - Up 1 Instruction
IDC_MICRO_DISPC - Snap to PC
IDC_MICRO_DISBP - Snap to Breakpoint
IDC_MICRO_DISDN - Down 1 Instruction
IDC_MICRO_DISPGDN - Down 1 Page

Registers:
IDC_MICRO_REGX - X
IDC_MICRO_REGY - Y
IDC_MICRO_REGA - A
IDC_MICRO_REGSP - SP
IDC_MICRO_REGPC - PC
IDC_MICRO_REGFN - N flag
IDC_MICRO_REGFV - V flag
IDC_MICRO_REGFD - D flag
IDC_MICRO_REGFI - I flag
IDC_MICRO_REGFZ - Z flag
IDC_MICRO_REGFC - C flag
IDC_MICRO_REGWATCH - Watch address
IDC_MICRO_REGCURSOR - Cursor location
IDC_MICRO_REGBREAK - Breakpoint address
IDC_MICRO_REGSCAN - Scanline
IDC_MICRO_REGMODE - PPU mode
IDC_MICRO_REGBADOP - Show bad opcodes

Controls:
IDC_MICRO_NMI - Generate NMI
IDC_MICRO_RESET - Generate RESET
IDC_MICRO_IRQ - Generate IRQ
IDC_MICRO_JMP - JMP to cursor
IDC_MICRO_BREAK - Set breakpoint
IDC_MICRO_STEP - Step
IDC_MICRO_RUNTO - Run to breakpoint
IDC_MICRO_WRITE - Write to memory

Banks:
IDC_MICRO_BANKENAB - Enable bankswitch detection
IDC_MICRO_BANKCLR - Clear 'switched banks'
IDC_MICRO_BANKLIST - Listing of switched banks


Watch:
IDC_MICRO_WATCHENAB - Enable watch
IDC_MICRO_WATCHLIST - Watch listing
IDC_MICRO_WATCHUP2 - Up 16 bytes
IDC_MICRO_WATCHUP1 - Up 1 byte
IDC_MICRO_WATCHDN1 - Down 1 byte
IDC_MICRO_WATCHDN2 - Down 16 bytes
*/

static	HWND	BugWnd;
static	BYTE	RegX, RegY, RegA, RegP, RegSP;
static	WORD	RegPC, RegWatch, RegCursor, RegBreak;
static	BOOL	BadOps, EnabWatch, EnabBanks;
static	BOOL	BankChanged[12];

static	WORD	CursorRel[4];

void	ShowRegs (void)
{
	char buf[16];
	BYTE mode;
	int scanline;
	WORD cycles;
	BOOL a = TRUE;

	a &= WriteByte(0x02);	// read registers

	a &= ReadByteEx(&RegA,10,FALSE);
	a &= ReadByteEx(&RegX,10,FALSE);
	a &= ReadByteEx(&RegY,10,FALSE);
	a &= ReadByteEx(&RegP,10,FALSE);
	a &= ReadByteEx(&RegSP,10,FALSE);
	a &= ReadByteEx((BYTE *)&RegPC+0,10,FALSE);
	a &= ReadByteEx((BYTE *)&RegPC+1,10,FALSE);
	a &= ReadByteEx((BYTE *)&RegBreak+0,10,FALSE);
	a &= ReadByteEx((BYTE *)&RegBreak+1,10,FALSE);
	a &= ReadByteEx((BYTE *)&cycles+0,10,FALSE);
	a &= ReadByteEx((BYTE *)&cycles+1,10,FALSE);
	a &= ReadByteEx(&mode,10,FALSE);
	if (!a)
	{
		MessageBox(BugWnd,"Timeout while retrieving registers!",CMD_NAME,MB_OK | MB_ICONERROR);
		return;
	}
	mode &= 0x40;

	if (mode)
		scanline = (27507 - cycles) * 3 / 341;
	else	
    scanline = -cycles * 3 / 341;

	sprintf(buf, "%02X", RegX);	SetDlgItemText(BugWnd, IDC_MICRO_REGX, buf);
	sprintf(buf, "%02X", RegY);	SetDlgItemText(BugWnd, IDC_MICRO_REGY, buf);
	sprintf(buf, "%02X", RegA);	SetDlgItemText(BugWnd, IDC_MICRO_REGA, buf);
	sprintf(buf, "%02X", RegSP);	SetDlgItemText(BugWnd, IDC_MICRO_REGSP, buf);
	sprintf(buf, "%04X", RegPC);	SetDlgItemText(BugWnd, IDC_MICRO_REGPC, buf);

	CheckDlgButton(BugWnd, IDC_MICRO_REGFN, (RegP & 0x80) ? BST_CHECKED : BST_UNCHECKED);
	CheckDlgButton(BugWnd, IDC_MICRO_REGFV, (RegP & 0x40) ? BST_CHECKED : BST_UNCHECKED);
	CheckDlgButton(BugWnd, IDC_MICRO_REGFD, (RegP & 0x08) ? BST_CHECKED : BST_UNCHECKED);
	CheckDlgButton(BugWnd, IDC_MICRO_REGFI, (RegP & 0x04) ? BST_CHECKED : BST_UNCHECKED);
	CheckDlgButton(BugWnd, IDC_MICRO_REGFZ, (RegP & 0x02) ? BST_CHECKED : BST_UNCHECKED);
	CheckDlgButton(BugWnd, IDC_MICRO_REGFC, (RegP & 0x01) ? BST_CHECKED : BST_UNCHECKED);

	sprintf(buf, "%04X", RegBreak);	SetDlgItemText(BugWnd, IDC_MICRO_REGBREAK, buf);
	sprintf(buf, "%04X", RegWatch);	SetDlgItemText(BugWnd, IDC_MICRO_REGWATCH, buf);
	sprintf(buf, "%04X", RegCursor);SetDlgItemText(BugWnd, IDC_MICRO_REGCURSOR, buf);
	SetDlgItemInt(BugWnd, IDC_MICRO_REGSCAN, scanline, TRUE);
	SetDlgItemText(BugWnd, IDC_MICRO_REGMODE, mode ? "Render" : "VBlank");
}

void	ShowRegs2 (void)
{
	char buf[16];
	sprintf(buf, "%04X", RegWatch);	SetDlgItemText(BugWnd, IDC_MICRO_REGWATCH, buf);
	sprintf(buf, "%04X", RegCursor);SetDlgItemText(BugWnd, IDC_MICRO_REGCURSOR, buf);
}

static	BYTE	oldbanks[64];

void	DoBanks (void)
{
	char str[256];
	BYTE banks[64];
	int i;
	
	if (EnabBanks)
	{
		WriteByte(0x0C);
		for (i = 0; i < 64; i++)
			if (!ReadByteEx(&banks[i], 1, FALSE))
				break;
		if (i != 64)
			return;

		for (i = 0; i < 4; i++)
			if (memcmp(&banks[i * 8], &oldbanks[i * 8], 8))
				BankChanged[i] = TRUE;

		for (i = 0; i < 8; i++)
			if (memcmp(&banks[32 + i * 4], &oldbanks[32 + i * 4], 4))
				BankChanged[i+4] = TRUE;
		memcpy(oldbanks, banks, 64);
	}

	SendDlgItemMessage(BugWnd, IDC_MICRO_BANKLIST, LB_RESETCONTENT, 0, 0);
	sprintf(str, "P:\t%s\t%s\t%s\t%s",
		BankChanged[0] ? "8" : "-",
		BankChanged[1] ? "A" : "-",
		BankChanged[2] ? "C" : "-",
		BankChanged[3] ? "E" : "-");
	SendDlgItemMessage(BugWnd, IDC_MICRO_BANKLIST, LB_ADDSTRING, 0, (LPARAM)str);

	sprintf(str, "C:\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s",
		BankChanged[4] ? "0" : "-",
		BankChanged[5] ? "1" : "-",
		BankChanged[6] ? "2" : "-",
		BankChanged[7] ? "3" : "-",
		BankChanged[8] ? "4" : "-",
		BankChanged[9] ? "5" : "-",
		BankChanged[10] ? "6" : "-",
		BankChanged[11] ? "7" : "-");
	SendDlgItemMessage(BugWnd, IDC_MICRO_BANKLIST, LB_ADDSTRING, 0, (LPARAM)str);
}

void	DumpBs (void)
{
	BYTE watchdata[64];
	char str[256];
	int i;

	SendDlgItemMessage(BugWnd, IDC_MICRO_WATCHLIST, LB_RESETCONTENT, 0, 0);

	if (!EnabWatch)
		return;

	WriteByte(0x04);
	WriteByte((BYTE)(RegWatch & 0xFF));
	WriteByte((BYTE)(RegWatch >> 8));
	WriteByte(0x40);

	for (i = 0; i < 64; i++)
		ReadByte(&watchdata[i]);

	for (i = 0; i < 64; i += 16)
	{
		sprintf(str,"%04X\t%02X\t%02X\t%02X\t%02X\t%02X\t%02X\t%02X\t%02X\t%02X\t%02X\t%02X\t%02X\t%02X\t%02X\t%02X\t%02X", (WORD)(RegWatch + i),
			watchdata[i+0], watchdata[i+1], watchdata[i+2], watchdata[i+3], watchdata[i+4], watchdata[i+5], watchdata[i+6], watchdata[i+7],
			watchdata[i+8], watchdata[i+9], watchdata[i+10], watchdata[i+11], watchdata[i+12], watchdata[i+13], watchdata[i+14], watchdata[i+15]);
		SendDlgItemMessage(BugWnd, IDC_MICRO_WATCHLIST, LB_ADDSTRING, 0, (LPARAM)str);
	}
}

extern enum ADDRMODE { IMP, ACC, IMM, ADR, ABS, IND, REL, ABX, ABY, ZPG, ZPX, ZPY, INX, INY, ERR, NUM_ADDR_MODES };
extern enum ADDRMODE TraceAddrMode[256];
extern unsigned char TraceAddrBytes[NUM_ADDR_MODES];
extern char TraceArr[256][5];

int	DisLine (WORD Addr, BYTE *data, int offset, int len)
{
	char str[256];
	int pc = Addr + offset;
	BYTE OpData[3] = { data[offset+0], data[offset+1], data[offset+2] };
	char *Instruct = TraceArr[OpData[0]];
	int AddrMode = TraceAddrMode[OpData[0]];
	int InstLen = TraceAddrBytes[AddrMode];
	WORD Operand;

	if (!BadOps && Instruct[0] == '*')
	{
		AddrMode = ERR;
		Instruct = " ???";
		InstLen = 1;
	}

	if (offset + InstLen > len)
		AddrMode = NUM_ADDR_MODES;

	switch (AddrMode)
	{
	case IND:	case ADR:	case ABS:	case ABX:	case ABY:
		Operand = OpData[1] | (OpData[2] << 8);
		break;
	case IMM:	case ZPG:	case ZPX:	case ZPY:	case INX:	case INY:
		Operand = OpData[1];
		break;
	case IMP:	case ACC:	case ERR:
		break;
	case REL:
		Operand = pc + 2 + (signed char)OpData[1];
		break;
	}

	switch (AddrMode)
	{
	case IMP:	sprintf(str,"%04X\t%02X\t\t\t%s",			pc,OpData[0],				Instruct);		break;
	case ERR:	sprintf(str,"%04X\t%02X\t\t\t%s",			pc,OpData[0],				Instruct);		break;
	case ACC:	sprintf(str,"%04X\t%02X\t\t\t%s A",			pc,OpData[0],				Instruct);		break;
	case IMM:	sprintf(str,"%04X\t%02X\t%02X\t\t%s #$%02X",		pc,OpData[0],OpData[1],			Instruct,Operand);	break;
	case REL:	sprintf(str,"%04X\t%02X\t%02X\t\t%s $%04X",		pc,OpData[0],OpData[1],			Instruct,Operand);	break;
	case ZPG:	sprintf(str,"%04X\t%02X\t%02X\t\t%s $%02X",		pc,OpData[0],OpData[1],			Instruct,Operand);	break;
	case ZPX:	sprintf(str,"%04X\t%02X\t%02X\t\t%s $%02X,X",		pc,OpData[0],OpData[1],			Instruct,Operand);	break;
	case ZPY:	sprintf(str,"%04X\t%02X\t%02X\t\t%s $%02X,Y",		pc,OpData[0],OpData[1],			Instruct,Operand);	break;
	case INX:	sprintf(str,"%04X\t%02X\t%02X\t\t%s ($%02X,X)",		pc,OpData[0],OpData[1],			Instruct,Operand);	break;
	case INY:	sprintf(str,"%04X\t%02X\t%02X\t\t%s ($%02X),Y",		pc,OpData[0],OpData[1],			Instruct,Operand);	break;
	case ADR:	sprintf(str,"%04X\t%02X\t%02X\t%02X\t%s $%04X",		pc,OpData[0],OpData[1],OpData[2],	Instruct,Operand);	break;
	case ABS:	sprintf(str,"%04X\t%02X\t%02X\t%02X\t%s $%04X",		pc,OpData[0],OpData[1],OpData[2],	Instruct,Operand);	break;
	case IND:	sprintf(str,"%04X\t%02X\t%02X\t%02X\t%s ($%04X)",	pc,OpData[0],OpData[1],OpData[2],	Instruct,Operand);	break;
	case ABX:	sprintf(str,"%04X\t%02X\t%02X\t%02X\t%s $%04X,X",	pc,OpData[0],OpData[1],OpData[2],	Instruct,Operand);	break;
	case ABY:	sprintf(str,"%04X\t%02X\t%02X\t%02X\t%s $%04X,Y",	pc,OpData[0],OpData[1],OpData[2],	Instruct,Operand);	break;
	default:	if (InstLen == 1)
				sprintf(str,"%04X\t%02X\t\t\t.db %02X",		pc,OpData[0],OpData[0]);
			else if (InstLen == 2)
				sprintf(str,"%04X\t%02X\t%02X\t\t.db %02X,%02X",pc,OpData[0],OpData[1],OpData[0],OpData[1]);			break;
	}
	SendDlgItemMessage(BugWnd, IDC_MICRO_DISASM, LB_ADDSTRING, 0, (LPARAM)str);
	return InstLen;
}

void	Update (void)
{
	BYTE RAM0[75], RAM1[25];
	WORD BackPC;
	WORD DisPC;
	BYTE len1, len2;
	int len;
	int i;

	DoBanks();
	ShowRegs2();

	DumpBs();

	WriteByte(0x05);		// save PC
	ReadByte((BYTE *)&BackPC+0);
	ReadByte((BYTE *)&BackPC+1);

	WriteByte(0x06);		// set PC to cursor pos
	WriteByte((BYTE)(RegCursor & 0xFF));
	WriteByte((BYTE)(RegCursor >> 8));

	if (BadOps)
		WriteByte(0x07);
	else	WriteByte(0x03);	// do disassembly

	ReadByte(&len1);

	for (i = 0; i < len1; i++)
		ReadByte(&RAM0[i]);

	len2 = 0;
	for (i = 0; i < 8; i++)
	{
		BYTE x;
		ReadByte(&RAM1[len2++]);
		ReadByte(&x);
		if (x == 3)
		{
			ReadByte(&RAM1[len2++]);
			x--;
		}
		if (x == 2)
			ReadByte(&RAM1[len2++]);
	}

	SendDlgItemMessage(BugWnd, IDC_MICRO_DISASM, LB_RESETCONTENT, 0, 0);	// clear the disasm box

	DisPC = RegCursor - len1;
	len = 0;
	for (i = 0; i < 7; i++)
		len += DisLine(DisPC, RAM0, len, len1);
	CursorRel[0] = DisPC;
	CursorRel[1] = DisPC + len;
	len += DisLine(DisPC, RAM0, len, len1);

	DisPC = RegCursor;
	len = 0;
	len += DisLine(DisPC, RAM1, len, len2);
	CursorRel[2] = DisPC + len;
	for (i = 0; i < 7; i++)
		len += DisLine(DisPC, RAM1, len, len2);
	CursorRel[3] = DisPC + len;

	SendDlgItemMessage(BugWnd, IDC_MICRO_DISASM, LB_SETCURSEL, 8, 0);	// put selection at cursor

	ReadByteEx(&len2,10,FALSE);

	WriteByte(0x06);		// restore PC
	WriteByte((BYTE)(BackPC & 0xFF));
	WriteByte((BYTE)(BackPC >> 8));
}

void	WriteRegs (void)
{
	if (RegSP > 0xEF)
		RegSP = 0xEF;
	WriteByte(0x01);
	WriteByte(RegA);
	WriteByte(RegX);
	WriteByte(RegY);
	WriteByte(RegP);
	WriteByte(RegSP);

	WriteByte((BYTE)(RegPC & 0xFF));
	WriteByte((BYTE)(RegPC >> 8));

	WriteByte((BYTE)(RegBreak & 0xFF));
	WriteByte((BYTE)(RegBreak >> 8));
}

int	GetRegister (void)
{
	int n;
	PromptTitle = "Enter register value (hexadecimal):";
	if (!Prompt(BugWnd))
		return -1;
	sscanf(PromptResult,"%X",&n);
	return n;
}

LRESULT CALLBACK DLG_MicroBug(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	int i;
	char txt[256];
	switch (message)
	{
	case WM_INITDIALOG:
		BugWnd = hDlg;
		{
			const int tabstop_A = 14;
			const int tabstop_B = 8;
			SendDlgItemMessage(hDlg, IDC_MICRO_DISASM, LB_SETTABSTOPS, 1, (LPARAM)&tabstop_A);
			SendDlgItemMessage(hDlg, IDC_MICRO_WATCHLIST, LB_SETTABSTOPS, 1, (LPARAM)&tabstop_A);
			SendDlgItemMessage(hDlg, IDC_MICRO_BANKLIST, LB_SETTABSTOPS, 1, (LPARAM)&tabstop_B);
		}

		RegX = 0x00;
		RegY = 0x00;
		RegA = 0x00;
		RegP = 0x00;
		RegSP = 0xFF;
		RegPC = 0x8000;
		RegWatch = 0x0000;
		RegCursor = 0x8000;
		RegBreak = 0x8000;
		BadOps = FALSE;
		EnabWatch = FALSE;
		EnabBanks = FALSE;
		ShowRegs();
		RegCursor = RegPC;
		Update();	// update everything
		return TRUE;
		break;

	case WM_COMMAND:
		switch (LOWORD(wParam))
		{
		case IDC_MICRO_DISASM:
			i = SendDlgItemMessage(BugWnd, IDC_MICRO_DISASM, LB_GETCURSEL, 0, 0);
			if (i == -1)
				break;
			SendDlgItemMessage(BugWnd, IDC_MICRO_DISASM, LB_GETTEXT, i, (LPARAM)txt);
			sscanf(txt, "%04X\t", &i);
			if (HIWORD(wParam) == LBN_SELCHANGE)
			{	// set cursor
				RegCursor = i;
				Update();
			}
			if (HIWORD(wParam) == LBN_DBLCLK)
			{
				// set breakpoint
				RegBreak = i;
				WriteRegs();
				ShowRegs();
				Update();
			}
			break;
		case IDC_MICRO_DISPGUP:
			RegCursor = CursorRel[0];
			Update();
			break;
		case IDC_MICRO_DISUP:
			RegCursor = CursorRel[1];
			Update();
			break;
		case IDC_MICRO_DISPC:
			RegCursor = RegPC;
			Update();
			break;
		case IDC_MICRO_DISBP:
			RegCursor = RegBreak;
			Update();
			break;
		case IDC_MICRO_DISDN:
			RegCursor = CursorRel[2];
			Update();
			break;
		case IDC_MICRO_DISPGDN:
			RegCursor = CursorRel[3];
			Update();
			break;

		case IDC_MICRO_REGX:
			i = GetRegister();
			if (i != -1)
			{
				RegX = i;
				WriteRegs();
				ShowRegs();
				Update();
			}
			break;
		case IDC_MICRO_REGY:
			i = GetRegister();
			if (i != -1)
			{
				RegY = i;
				WriteRegs();
				ShowRegs();
				Update();
			}
			break;
		case IDC_MICRO_REGA:
			i = GetRegister();
			if (i != -1)
			{
				RegA = i;
				WriteRegs();
				ShowRegs();
				Update();
			}
			break;
		case IDC_MICRO_REGSP:
			i = GetRegister();
			if (i != -1)
			{
				RegSP = i;
				WriteRegs();
				ShowRegs();
				Update();
			}
			break;
		case IDC_MICRO_REGPC:
			i = GetRegister();
			if (i != -1)
			{
				RegPC = i;
				WriteRegs();
				ShowRegs();
				Update();
			}

		case IDC_MICRO_REGFN:
			RegP &= 0x7F;
			RegP |= (IsDlgButtonChecked(hDlg, IDC_MICRO_REGFN) == BST_CHECKED) ? 0x80 : 0x00;
			WriteRegs();
			ShowRegs();
			Update();
			break;
		case IDC_MICRO_REGFV:
			RegP &= 0xBF;
			RegP |= (IsDlgButtonChecked(hDlg, IDC_MICRO_REGFV) == BST_CHECKED) ? 0x40 : 0x00;
			WriteRegs();
			ShowRegs();
			Update();
			break;
		case IDC_MICRO_REGFD:
			RegP &= 0xF7;
			RegP |= (IsDlgButtonChecked(hDlg, IDC_MICRO_REGFD) == BST_CHECKED) ? 0x08 : 0x00;
			WriteRegs();
			ShowRegs();
			Update();
			break;
		case IDC_MICRO_REGFI:
			RegP &= 0xFB;
			RegP |= (IsDlgButtonChecked(hDlg, IDC_MICRO_REGFI) == BST_CHECKED) ? 0x04 : 0x00;
			WriteRegs();
			ShowRegs();
			Update();
			break;
		case IDC_MICRO_REGFZ:
			RegP &= 0xFD;
			RegP |= (IsDlgButtonChecked(hDlg, IDC_MICRO_REGFZ) == BST_CHECKED) ? 0x02 : 0x00;
			WriteRegs();
			ShowRegs();
			Update();
			break;
		case IDC_MICRO_REGFC:
			RegP &= 0xFE;
			RegP |= (IsDlgButtonChecked(hDlg, IDC_MICRO_REGFC) == BST_CHECKED) ? 0x01 : 0x00;
			WriteRegs();
			ShowRegs();
			Update();
			break;
		case IDC_MICRO_REGWATCH:
			i = GetRegister();
			if (i != -1)
			{
				RegWatch = i;
				Update();
			}
			break;
		case IDC_MICRO_REGCURSOR:
			i = GetRegister();
			if (i != -1)
			{
				RegCursor = i;
				Update();
			}
			break;
		case IDC_MICRO_REGBREAK:
			i = GetRegister();
			if (i != -1)
			{
				RegBreak = i;
				WriteRegs();
				ShowRegs();
				Update();
			}
		case IDC_MICRO_REGBADOP:
			BadOps = (IsDlgButtonChecked(hDlg, IDC_MICRO_REGBADOP) == BST_CHECKED);
			Update();
			break;

		case IDC_MICRO_NMI:
			WriteByte(0x08);
			ShowRegs();
			RegCursor = RegPC;
			Update();
			break;
		case IDC_MICRO_RESET:
			WriteByte(0x09);
			ShowRegs();
			RegCursor = RegPC;
			Update();
			break;
		case IDC_MICRO_IRQ:
			WriteByte(0x0A);
			ShowRegs();
			RegCursor = RegPC;
			Update();
			break;

		case IDC_MICRO_JMP:
			RegPC = RegCursor;
			WriteRegs();
			ShowRegs();
			Update();
			break;
		case IDC_MICRO_BREAK:
			RegBreak = RegCursor;
			WriteRegs();
			ShowRegs();
			Update();
			break;
		case IDC_MICRO_STEP:
			WriteByte(0x00);
			ReadByte((BYTE *)&i);
			ShowRegs();
			RegCursor = RegPC;
			Update();
			break;
		case IDC_MICRO_RUNTO:
			{
				BYTE status;
				WriteByte(0x0D);
				OpenStatus(hDlg);
				StatusText("Running code - press OK to halt.");
				//OLD WriteByteAsync(0x00);       //do not write starting byte  CHANGED
				StatusButtonAsync(TRUE);
				while (1)
				{
					if (StatusButtonPressed())
					{
						//OLD WriteByteAsync(0xAA);   //put data on bus, do not format as write
            WriteByte(0xAA);  //NEW send break byte CHANGED
						break;
					}
					//OLD if (ReadByteAsync())      //check if byte ready to receive
          if (ReadByteReady())      //check if byte ready to receive  CHANGED
						break;
				}
				StatusButtonAsync(FALSE);
				ReadByte(&status);
				if (status == 1)
					StatusText("HLT instruction encountered!");
				else if (status == 2)
					StatusText("Breakpoint reached!");
				else if (status == 3)
					StatusText("User halted execution!");
				else
          StatusText("Unknown error!");
				Sleep(SLEEP_LONG);
				CloseStatus();
			}
			ShowRegs();
			RegCursor = RegPC;
			Update();
			break;
		case IDC_MICRO_WRITE:
			{
				int address, data;
				PromptTitle = "Enter address (hexadecimal):";
				if (!Prompt(hDlg))
					break;
				sscanf(PromptResult,"%X",&address);
				PromptTitle = "Enter value (hexadecimal):";
				if (!Prompt(hDlg))
					break;
				sscanf(PromptResult,"%X",&data);
				WriteByte(0x0B);
				WriteByte((BYTE)(address & 0xFF));
				WriteByte((BYTE)(address >> 8));
				WriteByte((BYTE)data);
			}
			Update();
			break;

		case IDC_MICRO_BANKENAB:
			EnabBanks = (IsDlgButtonChecked(hDlg, IDC_MICRO_BANKENAB) == BST_CHECKED);
			Update();
			break;
		case IDC_MICRO_BANKCLR:
			for (i = 0; i < 12; i++)
				BankChanged[i] = FALSE;
			DoBanks();
			break;

		case IDC_MICRO_WATCHENAB:
			EnabWatch = (IsDlgButtonChecked(hDlg, IDC_MICRO_WATCHENAB) == BST_CHECKED);
			Update();
			break;
		case IDC_MICRO_WATCHUP2:
			RegWatch -= 16;
			ShowRegs2();
			DumpBs();
			break;
		case IDC_MICRO_WATCHUP1:
			RegWatch--;
			ShowRegs2();
			DumpBs();
			break;
		case IDC_MICRO_WATCHDN1:
			RegWatch++;
			ShowRegs2();
			DumpBs();
			break;
		case IDC_MICRO_WATCHDN2:
			RegWatch += 16;
			ShowRegs2();
			DumpBs();
			break;

		case IDOK:
			ResetNES(RESET_COPYMODE);
			EndDialog(hDlg,TRUE);
			return TRUE;
			break;
		}
		break;

	case WM_CLOSE:
		ResetNES(RESET_COPYMODE);
		EndDialog(hDlg,TRUE);
		return TRUE;
		break;
	}
	return FALSE;
}

BOOL	CMD_MICROBUG (void)
{
	OpenStatus(topHWnd);
	StatusText("Resetting USB CopyNES...");
	ResetNES(RESET_COPYMODE);
	StatusText("Initializing MicroBug...");
	if (!WriteByte(0xA0))
	{
		CloseStatus();
		return FALSE;
	}
	Sleep(SLEEP_SHORT);
	CloseStatus();
	return DialogBox(hInst,MAKEINTRESOURCE(IDD_MICROBUG),topHWnd,DLG_MicroBug);
}
