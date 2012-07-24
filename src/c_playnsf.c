#include "StdAfx.h"
#define	CMD_NAME	"Play NSF"

//CHANGE ME add block usb writes

static	char	NSF_name[33], NSF_artist[33], NSF_copyright[33];
static	BYTE	NSF_banks[8]; 
static	BYTE	NSF_cursong, NSF_totalsongs;

LRESULT CALLBACK DLG_PlayNSF(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	int i;
	switch (message)
	{
	case WM_INITDIALOG:
		SetDlgItemText(hDlg,IDC_NSF_TITLE,NSF_name);
		SetDlgItemText(hDlg,IDC_NSF_ARTIST,NSF_artist);
		SetDlgItemText(hDlg,IDC_NSF_COPYRIGHT,NSF_copyright);
		SetDlgItemInt(hDlg,IDC_NSF_CURSONG,NSF_cursong,FALSE);
		SetDlgItemInt(hDlg,IDC_NSF_MAXSONGS,NSF_totalsongs,FALSE);
		return TRUE;
	case WM_COMMAND:
		switch (LOWORD(wParam))
		{
		case IDOK:
			EndDialog(hDlg,TRUE);
			return TRUE;			break;
		case IDC_NSF_PREVIOUS:
			NSF_cursong--;
			if (NSF_cursong < 1)
				NSF_cursong = NSF_totalsongs;
			SetDlgItemInt(hDlg,IDC_NSF_CURSONG,NSF_cursong,FALSE);
			NSF_cursong--;
		case IDC_NSF_NEXT:
			NSF_cursong++;
			if (NSF_cursong > NSF_totalsongs)
				NSF_cursong = 1;
			SetDlgItemInt(hDlg,IDC_NSF_CURSONG,NSF_cursong,FALSE);
		case IDC_NSF_REPLAY:
	/* FIXME: find out why this code breaks after running once */
			ResetNES(RESET_COPYMODE);
			if (!WriteByte(0x9F))	// Play NSF
			{
				EndDialog(hDlg,FALSE);
				return TRUE;
			}
			Sleep(SLEEP_SHORT);
			for (i = 0; i < 8; i++)
			{
				if (!WriteByte(NSF_banks[i]))
				{
					EndDialog(hDlg,FALSE);
					return TRUE;
				}
			}
			if (!WriteByte(NSF_totalsongs) || !WriteByte(NSF_cursong))
			{
				EndDialog(hDlg,FALSE);
				return TRUE;
			}
			return TRUE;			break;
		}
		break;
	case WM_CLOSE:
		EndDialog(hDlg,TRUE);
		return TRUE;			break;
	}
	return FALSE;
}

BOOL	LoadNSF (char *filename)
{
	FILE *NSF;
	BYTE header[128];
	int i, nbytes, nblks, nrem;

	NSF = fopen(filename,"rb");
	if (NSF == NULL)
	{
		MessageBox(topHWnd,"Unable to open file!",MSGBOX_TITLE,MB_OK);
		return FALSE;
	}

	OpenStatus(topHWnd);
	StatusText("Resetting USB CopyNES...");
	ResetNES(RESET_COPYMODE);

	StatusText("Setting USB CopyNES to NSF player mode...");
	if (!WriteByte(0x8E))
	{
		CloseStatus();
		return FALSE;
	}

	if (fread(header,1,128,NSF) != 128)
		return FALSE;

	StatusText("Uploading NSF header...");

	if (!WriteByte(header[0x8]) || !WriteByte(header[0x9]) || !WriteByte(header[0xA]) ||
		!WriteByte(header[0xB]) || !WriteByte(header[0xC]) || !WriteByte(header[0xD]))
	{
		CloseStatus();
		return FALSE;
	}

	fseek(NSF,0,SEEK_END);
	nbytes = ftell(NSF) - 128;
	if (!WriteByte((BYTE)(nbytes >> 0)) || !WriteByte((BYTE)(nbytes >> 8)) || !WriteByte((BYTE)(nbytes >> 16)))
	{
		CloseStatus();
		return FALSE;
	}
	nbytes++;
	fseek(NSF,128,SEEK_SET);
	nblks = nbytes / 4096;
	nrem = nbytes % 4096;

	for (i = 0; i < 8; i++)
	{
		if (!WriteByte(NSF_banks[i] = header[0x70 | i]));
		{
			CloseStatus();
			return FALSE;
		}
	}
	if (!WriteByte(NSF_totalsongs = header[0x6]) || !WriteByte(NSF_cursong = header[0x7]))
	{
		CloseStatus();
		return FALSE;
	}

	StatusText("Uploading NSF data...");
	if (nblks)
	{
		int v, a;
		for (v = 0; v < nblks; v++)
		{
			for (a = 0; a < 4096; a++)
			{
				BYTE r;
				if (fread(&r,1,1,NSF) == 0)
				{
					MessageBox(topHWnd,"Error! Failed to read NSF data!",MSGBOX_TITLE,MB_OK);
					CloseStatus();
					return FALSE;
				}
				if (!WriteByte(r))
				{
					CloseStatus();
					return FALSE;
				}
			}
			StatusPercent(v*100/nblks);
		}
	}
	if (nrem)
	{
		int a;
		for (a = 0; a < nrem; a++)
		{
			BYTE r;
			if (fread(&r,1,1,NSF) == 0)
			{
				StatusText("Error! Failed to read NSF data!");
				StatusOK();
				return FALSE;
			}
			if (!WriteByte(r))
			{
				CloseStatus();
				return FALSE;
			}
		}
		StatusPercent(100);
	}
	StatusText("...done!");
	Sleep(SLEEP_SHORT);
	fseek(NSF,14,SEEK_SET);
	fread(NSF_name,1,32,NSF);
	fread(NSF_artist,1,32,NSF);
	fread(NSF_copyright,1,32,NSF);
	NSF_name[32] = NSF_artist[32] = NSF_copyright[32] = 0;
	fclose(NSF);
	CloseStatus();
	return DialogBox(hInst,MAKEINTRESOURCE(IDD_PLAYNSF),topHWnd,DLG_PlayNSF);
}

BOOL	CMD_PLAYNSF (void)
{
	BOOL result;
	char filename[MAX_PATH];
	if (!PromptFile(topHWnd,"NSF Files (*.NSF)\0*.nsf\0\0",filename,NULL,NULL,"Select an NSF","nsf",FALSE))
		return FALSE;
	result = LoadNSF(filename);
	ResetNES(RESET_COPYMODE);
	return result;
}
