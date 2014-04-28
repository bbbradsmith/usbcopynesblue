#include "StdAfx.h"
#define	CMD_NAME	"Play NSF"

//CHANGE ME add block usb writes

// defined in c_ramcart.c
// used to load 32k NSF as an NROM
extern	BOOL	RAMCartLoad (char* filedata, long int filesize, int load_type);

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
	int i, j, nbytes, nblks, nrem;
	char* nsfdata;
	char* nesdata;
	unsigned int loadaddr;
	BOOL ramcart = FALSE;
	BOOL bankswitch = FALSE;

	NSF = fopen(filename,"rb");
	if (NSF == NULL)
	{
		StatusText("Unable to open file!");
		StatusOK();
		return FALSE;
	}

	OpenStatus(topHWnd);

	if (fread(header,1,128,NSF) != 128)
	{
		StatusText("Unable to read NSF header.");
		StatusOK();
		return FALSE;
	}

	// gather file size
	fseek(NSF,0,SEEK_END);
	nbytes = ftell(NSF) - 128;
	fseek(NSF,128,SEEK_SET);

	// load NSF data
	nsfdata = calloc(16 + (64*1024), 1);
	if (nsfdata == NULL)
	{
		StatusText("Out of memory for temporary NSF storage!");
		StatusOK();
		return FALSE;
	}
	fread(nsfdata, 1, 64*1024, NSF);
	fclose(NSF);

	// temporary space for dummy NES upload to ramcart
	nesdata = calloc(16 + (64*1024), 1);
	if (nesdata == NULL)
	{
		free(nsfdata);
		StatusText("Out of memory for temporary NES storage!");
		StatusOK();
		return FALSE;
	}

	// allow user to upload as RAMCart
	StatusText("Upload NSF data to RAMCart...");

	// dummy iNES file for upload
	nesdata[0x0] = 'N';
	nesdata[0x1] = 'E';
	nesdata[0x2] = 'S';
	nesdata[0x3] = 0x1A;
	nesdata[0x4] = 2; // 32k PRG
	// rest is 0s

	loadaddr = header[0x8] + (header[0x9] * 256);

	for (i=0; i < 8; ++i)
	{
		if (header[0x70+i] != 0)
			bankswitch = TRUE;
	}

	if (bankswitch) // some <32k NSFs don't really bankswitch, try and accomodate
	{
		for (i=0; i < 8; ++i)
		{
			for (j=0; j<4096; ++j)
			{
				BYTE r = 0;
				int readaddr = j + (header[0x70+i] * 4096) - (loadaddr & 0xFFF);
				if (readaddr >= 0)
					r = nsfdata[readaddr];
				nesdata[(i*4096)+j+16] = r;
			}
		}
	}
	else // just place all NSF data at load address (note padding to 64k keeps this safe)
	{
		memcpy(nesdata + 16 + (loadaddr & 0x7FFF), nsfdata, 32 * 1024);
	}

	// send to ramcart
	if (RAMCartLoad(nesdata, 16+(64*1024),1))
	{
		ramcart = TRUE;

		if (nbytes > (32 * 1024))
			StatusText("NSF is larger than 32k, may not be playable.");
		if (bankswitch)
			StatusText("NSF is bankswitched, may not be playable.");

		// erase evidence of bankswitching
		nbytes = 32*1024;
		memcpy(nsfdata, nesdata+16, 64*1024);
		for (i=0; i<8; ++i) // no bankswitching
			header[0x70+i] = 0;
		header[0x9] = 0x80; // load 800
		header[0x8] = 0x00;
	}
	else
		StatusText("Failed or skipped.");
	free(nesdata);
	// ===========================

	StatusText("Resetting USB CopyNES...");
	ResetNES(RESET_COPYMODE);

	StatusText("Setting USB CopyNES to NSF player mode...");
	if (!WriteByte(0x8E))
	{
		free(nsfdata);
		StatusText("Unable to write!");
		StatusOK();
		return FALSE;
	}

	StatusText("Uploading NSF header...");

	if (!WriteByte(header[0x8]) || !WriteByte(header[0x9]) || !WriteByte(header[0xA]) ||
		!WriteByte(header[0xB]) || !WriteByte(header[0xC]) || !WriteByte(header[0xD]))
	{
		free(nsfdata);
		StatusText("Unable to write!");
		StatusOK();
		return FALSE;
	}

	if (!WriteByte((BYTE)(nbytes >> 0)) || !WriteByte((BYTE)(nbytes >> 8)) || !WriteByte((BYTE)(nbytes >> 16)))
	{
		free(nsfdata);
		StatusText("Unable to write!");
		StatusOK();
		return FALSE;
	}
	nbytes++;

	nblks = nbytes / 4096;
	nrem = nbytes % 4096;

	for (i = 0; i < 8; i++)
	{
		if (!WriteByte(NSF_banks[i] = header[0x70 | i]))
		{
			free(nsfdata);
			StatusText("Unable to write!");
			StatusOK();
			return FALSE;
		}
	}
	if (!WriteByte(NSF_totalsongs = header[0x6]) || !WriteByte(NSF_cursong = header[0x7]))
	{
		free(nsfdata);
		StatusText("Unable to write!");
		StatusOK();
		return FALSE;
	}
	StatusText("...done!");

	// this additional upload is still required
	// even if the upload was done via the ramcart option,
	// because the NSF player in the BIOS doesn't finish its job until after the upload;
	// hopefully this won't interfere with the ramcart itself (seems fine for PowerPakLite).
	{
		unsigned int pos = 0;
		StatusText("Uploading NSF data...");
		if (nblks)
		{
			int v;
			for (v = 0; v < nblks; v++)
			{
				if(!WriteBlock(nsfdata+pos,4096))
				{
					free(nsfdata);
					StatusText("Unable to write!");
					StatusOK();
					return FALSE;
				}
				pos += 4096;
				if ((pos + 4095) >= (64 * 4096)) pos = 0; // read safety

				StatusPercent(v*100/nblks);
			}
		}
		if (nrem)
		{
			if(!WriteBlock(nsfdata+pos,nrem))
			{
				free(nsfdata);
				StatusText("Unable to write!");
				StatusOK();
				return FALSE;
			}
			StatusPercent(100);
		}
		StatusText("...done!");
	}

	Sleep(SLEEP_SHORT);

	memcpy(NSF_name,     header+14   ,32);
	memcpy(NSF_artist,   header+14+32,32);
	memcpy(NSF_copyright,header+14+64,32);
	NSF_name[32] = NSF_artist[32] = NSF_copyright[32] = 0;
	free(nsfdata);

	StatusOK();
	return DialogBox(hInst,MAKEINTRESOURCE(IDD_PLAYNSF),topHWnd,DLG_PlayNSF);
}

BOOL	CMD_PLAYNSF (void)
{
	BOOL result;
	char filename[MAX_PATH];
	if (!PromptFile(topHWnd,"NSF Files (*.NSF)\0*.nsf\0\0",filename,NULL,Path_NSF,"Select an NSF","nsf",FALSE))
		return FALSE;
	result = LoadNSF(filename);
	ResetNES(RESET_COPYMODE);
	return result;
}
