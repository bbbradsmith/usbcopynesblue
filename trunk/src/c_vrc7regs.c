#include "StdAfx.h"
#include <commctrl.h>
#define	CMD_NAME	"VRC7 Register Tuner"

static	BYTE	instdata[16][8];
static	CHAR	filename[MAX_PATH];
static	BYTE	inst, oct;
static	BOOL	changed;
static	FILE	*data;

void	UpdateInstrument (HWND hDlg)
{
	int i;

	if (IsDlgButtonChecked(hDlg, IDC_VRC7_MTREMOLO) == BST_CHECKED)
		instdata[0][0] |= 0x80;
	else	instdata[0][0] &= ~0x80;
	if (IsDlgButtonChecked(hDlg, IDC_VRC7_MVIBRATO) == BST_CHECKED)
		instdata[0][0] |= 0x40;
	else	instdata[0][0] &= ~0x40;
	if (IsDlgButtonChecked(hDlg, IDC_VRC7_MSUSTAIN) == BST_CHECKED)
		instdata[0][0] |= 0x20;
	else	instdata[0][0] &= ~0x20;
	if (IsDlgButtonChecked(hDlg, IDC_VRC7_MKSR) == BST_CHECKED)
		instdata[0][0] |= 0x10;
	else	instdata[0][0] &= ~0x10;
	instdata[0][0] &= ~0x0F;
	i = SendDlgItemMessage(hDlg, IDC_VRC7_MMULTSLID, TBM_GETPOS, 0, 0);
	instdata[0][0] |= i & 0x0F;
	SetDlgItemInt(hDlg, IDC_VRC7_MMULTEDIT, i, FALSE);

	if (IsDlgButtonChecked(hDlg, IDC_VRC7_CTREMOLO) == BST_CHECKED)
		instdata[0][1] |= 0x80;
	else	instdata[0][1] &= ~0x80;
	if (IsDlgButtonChecked(hDlg, IDC_VRC7_CVIBRATO) == BST_CHECKED)
		instdata[0][1] |= 0x40;
	else	instdata[0][1] &= ~0x40;
	if (IsDlgButtonChecked(hDlg, IDC_VRC7_CSUSTAIN) == BST_CHECKED)
		instdata[0][1] |= 0x20;
	else	instdata[0][1] &= ~0x20;
	if (IsDlgButtonChecked(hDlg, IDC_VRC7_CKSR) == BST_CHECKED)
		instdata[0][1] |= 0x10;
	else	instdata[0][1] &= ~0x10;
	instdata[0][1] &= ~0x0F;
	i = SendDlgItemMessage(hDlg, IDC_VRC7_CMULTSLID, TBM_GETPOS, 0, 0);
	instdata[0][1] |= i & 0x0F;
	SetDlgItemInt(hDlg, IDC_VRC7_CMULTEDIT, i, FALSE);

	instdata[0][2] &= ~0xC0;
	i = SendDlgItemMessage(hDlg, IDC_VRC7_MKEYSLID, TBM_GETPOS, 0, 0);
	instdata[0][2] |= i << 6;
	SetDlgItemInt(hDlg, IDC_VRC7_MKEYEDIT, i, FALSE);

	instdata[0][2] &= ~0x1F;
	i = SendDlgItemMessage(hDlg, IDC_VRC7_MVOLSLID, TBM_GETPOS, 0, 0);
	instdata[0][2] |= i;
	SetDlgItemInt(hDlg, IDC_VRC7_MVOLEDIT, i, FALSE);

	instdata[0][3] &= ~0xC0;
	i = SendDlgItemMessage(hDlg, IDC_VRC7_CKEYSLID, TBM_GETPOS, 0, 0);
	instdata[0][3] |= i << 6;
	SetDlgItemInt(hDlg, IDC_VRC7_CKEYEDIT, i, FALSE);
	if (IsDlgButtonChecked(hDlg, IDC_VRC7_CFSINE) == BST_CHECKED)
		instdata[0][3] &= ~0x10;
	if (IsDlgButtonChecked(hDlg, IDC_VRC7_CHSINE) == BST_CHECKED)
		instdata[0][3] |= 0x10;
	if (IsDlgButtonChecked(hDlg, IDC_VRC7_MFSINE) == BST_CHECKED)
		instdata[0][3] &= ~0x08;
	if (IsDlgButtonChecked(hDlg, IDC_VRC7_MHSINE) == BST_CHECKED)
		instdata[0][3] |= 0x08;
	instdata[0][3] &= ~0x07;
	i = SendDlgItemMessage(hDlg, IDC_VRC7_CFEEDSLID, TBM_GETPOS, 0, 0);
	instdata[0][3] |= i;
	SetDlgItemInt(hDlg, IDC_VRC7_CFEEDEDIT, i, FALSE);

	instdata[0][4] &= ~0xF0;
	i = SendDlgItemMessage(hDlg, IDC_VRC7_MASLID, TBM_GETPOS, 0, 0);
	instdata[0][4] |= i << 4;
	SetDlgItemInt(hDlg, IDC_VRC7_MAEDIT, i, FALSE);
	instdata[0][4] &= ~0x0F;
	i = SendDlgItemMessage(hDlg, IDC_VRC7_MDSLID, TBM_GETPOS, 0, 0);
	instdata[0][4] |= i;
	SetDlgItemInt(hDlg, IDC_VRC7_MDEDIT, i, FALSE);

	instdata[0][5] &= ~0xF0;
	i = SendDlgItemMessage(hDlg, IDC_VRC7_CASLID, TBM_GETPOS, 0, 0);
	instdata[0][5] |= i << 4;
	SetDlgItemInt(hDlg, IDC_VRC7_CAEDIT, i, FALSE);
	instdata[0][5] &= ~0x0F;
	i = SendDlgItemMessage(hDlg, IDC_VRC7_CDSLID, TBM_GETPOS, 0, 0);
	instdata[0][5] |= i;
	SetDlgItemInt(hDlg, IDC_VRC7_CDEDIT, i, FALSE);

	instdata[0][6] &= ~0xF0;
	i = SendDlgItemMessage(hDlg, IDC_VRC7_MSSLID, TBM_GETPOS, 0, 0);
	instdata[0][6] |= i << 4;
	SetDlgItemInt(hDlg, IDC_VRC7_MSEDIT, i, FALSE);
	instdata[0][6] &= ~0x0F;
	i = SendDlgItemMessage(hDlg, IDC_VRC7_MRSLID, TBM_GETPOS, 0, 0);
	instdata[0][6] |= i;
	SetDlgItemInt(hDlg, IDC_VRC7_MREDIT, i, FALSE);

	instdata[0][7] &= ~0xF0;
	i = SendDlgItemMessage(hDlg, IDC_VRC7_CSSLID, TBM_GETPOS, 0, 0);
	instdata[0][7] |= i << 4;
	SetDlgItemInt(hDlg, IDC_VRC7_CSEDIT, i, FALSE);
	instdata[0][7] &= ~0x0F;
	i = SendDlgItemMessage(hDlg, IDC_VRC7_CRSLID, TBM_GETPOS, 0, 0);
	instdata[0][7] |= i;
	SetDlgItemInt(hDlg, IDC_VRC7_CREDIT, i, FALSE);
}

void	SelectInstrument (HWND hDlg, int newinst)
{
	if (inst)
		memcpy(instdata[inst], instdata[0], 8);	// save instrument data
	inst = newinst;

	CheckDlgButton(hDlg, IDC_VRC7_MTREMOLO, (instdata[inst][0] & 0x80) ? BST_CHECKED : BST_UNCHECKED);
	CheckDlgButton(hDlg, IDC_VRC7_MVIBRATO, (instdata[inst][0] & 0x40) ? BST_CHECKED : BST_UNCHECKED);
	CheckDlgButton(hDlg, IDC_VRC7_MSUSTAIN, (instdata[inst][0] & 0x20) ? BST_CHECKED : BST_UNCHECKED);
	CheckDlgButton(hDlg, IDC_VRC7_MKSR, (instdata[inst][0] & 0x10) ? BST_CHECKED : BST_UNCHECKED);
	SendDlgItemMessage(hDlg, IDC_VRC7_MMULTSLID, TBM_SETPOS, TRUE, instdata[inst][0] & 0xF);

	CheckDlgButton(hDlg, IDC_VRC7_CTREMOLO, (instdata[inst][1] & 0x80) ? BST_CHECKED : BST_UNCHECKED);
	CheckDlgButton(hDlg, IDC_VRC7_CVIBRATO, (instdata[inst][1] & 0x40) ? BST_CHECKED : BST_UNCHECKED);
	CheckDlgButton(hDlg, IDC_VRC7_CSUSTAIN, (instdata[inst][1] & 0x20) ? BST_CHECKED : BST_UNCHECKED);
	CheckDlgButton(hDlg, IDC_VRC7_CKSR, (instdata[inst][1] & 0x10) ? BST_CHECKED : BST_UNCHECKED);
	SendDlgItemMessage(hDlg, IDC_VRC7_CMULTSLID, TBM_SETPOS, TRUE, instdata[inst][1] & 0xF);

	SendDlgItemMessage(hDlg, IDC_VRC7_MKEYSLID, TBM_SETPOS, TRUE, (instdata[inst][2] >> 6) & 0x3);
	SendDlgItemMessage(hDlg, IDC_VRC7_MVOLSLID, TBM_SETPOS, TRUE, instdata[inst][2] & 0x1F);

	SendDlgItemMessage(hDlg, IDC_VRC7_CKEYSLID, TBM_SETPOS, TRUE, (instdata[inst][3] >> 6) & 0x3);
	SendDlgItemMessage(hDlg, IDC_VRC7_CFEEDSLID, TBM_SETPOS, TRUE, instdata[inst][3] & 0x7);

	CheckRadioButton(hDlg, IDC_VRC7_CFSINE, IDC_VRC7_CHSINE, (instdata[inst][3] & 0x10) ? IDC_VRC7_CHSINE : IDC_VRC7_CFSINE);
	CheckRadioButton(hDlg, IDC_VRC7_MFSINE, IDC_VRC7_MHSINE, (instdata[inst][3] & 0x08) ? IDC_VRC7_MHSINE : IDC_VRC7_MFSINE);

	SendDlgItemMessage(hDlg, IDC_VRC7_MASLID, TBM_SETPOS, TRUE, (instdata[inst][4] >> 4) & 0xF);
	SendDlgItemMessage(hDlg, IDC_VRC7_MDSLID, TBM_SETPOS, TRUE, instdata[inst][4] & 0xF);
	SendDlgItemMessage(hDlg, IDC_VRC7_CASLID, TBM_SETPOS, TRUE, (instdata[inst][5] >> 4) & 0xF);
	SendDlgItemMessage(hDlg, IDC_VRC7_CDSLID, TBM_SETPOS, TRUE, instdata[inst][5] & 0xF);
	SendDlgItemMessage(hDlg, IDC_VRC7_MSSLID, TBM_SETPOS, TRUE, (instdata[inst][6] >> 4) & 0xF);
	SendDlgItemMessage(hDlg, IDC_VRC7_MRSLID, TBM_SETPOS, TRUE, instdata[inst][6] & 0xF);
	SendDlgItemMessage(hDlg, IDC_VRC7_CSSLID, TBM_SETPOS, TRUE, (instdata[inst][7] >> 4) & 0xF);
	SendDlgItemMessage(hDlg, IDC_VRC7_CRSLID, TBM_SETPOS, TRUE, instdata[inst][7] & 0xF);

	UpdateInstrument(hDlg);
	SetDlgItemInt(hDlg, IDC_VRC7_INSTEDIT, inst, FALSE);
}

LRESULT CALLBACK DLG_VRC7Tuner(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	int i, j;
	switch (message)
	{
	case WM_INITDIALOG:
		SendDlgItemMessage(hDlg, IDC_VRC7_INSTSLID, TBM_SETRANGE, TRUE, MAKELONG(1,15));
		SendDlgItemMessage(hDlg, IDC_VRC7_OCTSLID, TBM_SETRANGE, TRUE, MAKELONG(0,7));
		
		SendDlgItemMessage(hDlg, IDC_VRC7_CMULTSLID, TBM_SETRANGE, TRUE, MAKELONG(0,15));
		SendDlgItemMessage(hDlg, IDC_VRC7_MMULTSLID, TBM_SETRANGE, TRUE, MAKELONG(0,15));

		SendDlgItemMessage(hDlg, IDC_VRC7_CKEYSLID, TBM_SETRANGE, TRUE, MAKELONG(0,3));
		SendDlgItemMessage(hDlg, IDC_VRC7_MKEYSLID, TBM_SETRANGE, TRUE, MAKELONG(0,3));

		SendDlgItemMessage(hDlg, IDC_VRC7_CFEEDSLID, TBM_SETRANGE, TRUE, MAKELONG(0,7));
		SendDlgItemMessage(hDlg, IDC_VRC7_MVOLSLID, TBM_SETRANGE, TRUE, MAKELONG(0,31));

		SendDlgItemMessage(hDlg, IDC_VRC7_CASLID, TBM_SETRANGE, TRUE, MAKELONG(0,15));
		SendDlgItemMessage(hDlg, IDC_VRC7_MASLID, TBM_SETRANGE, TRUE, MAKELONG(0,15));

		SendDlgItemMessage(hDlg, IDC_VRC7_CDSLID, TBM_SETRANGE, TRUE, MAKELONG(0,15));
		SendDlgItemMessage(hDlg, IDC_VRC7_MDSLID, TBM_SETRANGE, TRUE, MAKELONG(0,15));

		SendDlgItemMessage(hDlg, IDC_VRC7_CSSLID, TBM_SETRANGE, TRUE, MAKELONG(0,15));
		SendDlgItemMessage(hDlg, IDC_VRC7_MSSLID, TBM_SETRANGE, TRUE, MAKELONG(0,15));

		SendDlgItemMessage(hDlg, IDC_VRC7_CRSLID, TBM_SETRANGE, TRUE, MAKELONG(0,15));
		SendDlgItemMessage(hDlg, IDC_VRC7_MRSLID, TBM_SETRANGE, TRUE, MAKELONG(0,15));

		inst = 0;
		SelectInstrument(hDlg, 1);
		SendDlgItemMessage(hDlg, IDC_VRC7_INSTSLID, TBM_SETPOS, TRUE, inst);

		oct = 0xC4;
		SendDlgItemMessage(hDlg, IDC_VRC7_OCTSLID, TBM_SETPOS, TRUE, oct & 0x7);
		SetDlgItemInt(hDlg, IDC_VRC7_OCTEDIT, oct & 0x7, FALSE);

		CheckDlgButton(hDlg, IDC_VRC7_CUSTOM, (oct & 0x80) ? BST_CHECKED : BST_UNCHECKED);
		CheckDlgButton(hDlg, IDC_VRC7_BUILTIN, (oct & 0x40) ? BST_CHECKED : BST_UNCHECKED);
		changed = FALSE;

		return TRUE;
		break;

	case WM_COMMAND:
		switch (LOWORD(wParam))
		{
		case IDC_VRC7_CUSTOM:
			oct &= ~0x80;
			if (IsDlgButtonChecked(hDlg, IDC_VRC7_CUSTOM))
				oct |= 0x80;
			break;
		case IDC_VRC7_BUILTIN:
			oct &= ~0x40;
			if (IsDlgButtonChecked(hDlg, IDC_VRC7_BUILTIN))
				oct |= 0x40;
			break;

		case IDC_VRC7_MTREMOLO:
		case IDC_VRC7_MVIBRATO:
		case IDC_VRC7_MSUSTAIN:
		case IDC_VRC7_MKSR:
		case IDC_VRC7_CTREMOLO:
		case IDC_VRC7_CVIBRATO:
		case IDC_VRC7_CSUSTAIN:
		case IDC_VRC7_CKSR:
		case IDC_VRC7_CFSINE:
		case IDC_VRC7_CHSINE:
		case IDC_VRC7_MFSINE:
		case IDC_VRC7_MHSINE:
			changed = TRUE;
			EnableWindow(GetDlgItem(hDlg,IDC_VRC7_SAVE), TRUE);
			UpdateInstrument(hDlg);
			break;

		case IDC_VRC7_PLAY:
			WriteByte(0x55);
			WriteByte(0xAA);
			for (i = 0; i < 8; i++)
				WriteByte(instdata[0][i]);
			WriteByte(inst);
			WriteByte(oct);
			break;

		case IDC_VRC7_STOP:
			WriteByte(0x55);
			WriteByte(0xAA);
			for (i = 0; i < 8; i++)
				WriteByte(instdata[0][i]);
			WriteByte(inst);
			WriteByte(oct & ~(0x40|0x80));
			break;

		case IDC_VRC7_SAVE:
			SelectInstrument(hDlg, inst);	// save changes
			EnableWindow(GetDlgItem(hDlg,IDC_VRC7_SAVE), FALSE);
			changed = FALSE;
			fseek(data,8,SEEK_SET);
			for (i = 1; i < 16; i++)
			{
				for (j = 0; j < 8; j++)
					fwrite(&instdata[i][j],1,1,data);
			}
			rewind(data);
			break;

		case IDOK:
			if (!changed || (MessageBox(hDlg, "Really discard changes?", CMD_NAME, MB_YESNO | MB_ICONQUESTION) == IDYES))
				EndDialog(hDlg,TRUE);
			return TRUE;
			break;
		}
		break;

	case WM_HSCROLL:
		if ((HWND)lParam == GetDlgItem(hDlg,IDC_VRC7_INSTSLID))
			SelectInstrument(hDlg, SendDlgItemMessage(hDlg, IDC_VRC7_INSTSLID, TBM_GETPOS, 0, 0));
		else if ((HWND)lParam == GetDlgItem(hDlg,IDC_VRC7_OCTSLID))
		{
			oct &= 0xC0;
			oct |= SendDlgItemMessage(hDlg, IDC_VRC7_OCTSLID, TBM_GETPOS, 0, 0);
			SetDlgItemInt(hDlg, IDC_VRC7_OCTEDIT, (oct & 0x7), FALSE);
		}
		else
		{
			changed = TRUE;
			EnableWindow(GetDlgItem(hDlg,IDC_VRC7_SAVE), TRUE);
			UpdateInstrument(hDlg);
		}
		break;

	case WM_CLOSE:
		if (!changed || (MessageBox(hDlg, "Really discard changes?", CMD_NAME, MB_YESNO | MB_ICONQUESTION) == IDYES))
			EndDialog(hDlg,TRUE);
		return TRUE;
		break;
	}
	return FALSE;
}

BOOL	CMD_VRC7REGS (void)
{
	int i, j;
	BOOL status;

	if (!PromptFile(topHWnd,"VRC7 Instrument Data (*.vrc7)\0*.vrc7\0\0",filename,NULL,Path_MAIN,"Please select an instrument set...","vrc7",FALSE))
		return FALSE;
	data = fopen(filename, "r+b");
	if (data == NULL)
	{
		MessageBox(topHWnd, "Failed to open instrument data!", CMD_NAME, MB_OK | MB_ICONERROR);
		return FALSE;
	}

	for (i = 0; i < 16; i++)
		for (j = 0; j < 8; j++)
			fread(&instdata[i][j],1,1,data);

	OpenStatus(topHWnd);
	StatusText("Resetting USB CopyNES...");
	ResetNES(RESET_COPYMODE);
	StatusText("Loading plugin...");
	if (!LoadPlugin("regtest.bin"))
	{
		CloseStatus();
		return FALSE;
	}
	Sleep(SLEEP_SHORT);
	StatusText("Initializing plugin...");
	if (!RunCode())
	{
		CloseStatus();
		return FALSE;
	}
	Sleep(SLEEP_SHORT);
	CloseStatus();
	status = DialogBox(hInst,MAKEINTRESOURCE(IDD_VRC7TUNER),topHWnd,DLG_VRC7Tuner);
	fclose(data);
	ResetNES(RESET_COPYMODE);
	return status;
}
