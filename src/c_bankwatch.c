#include "StdAfx.h"
#include <commctrl.h>
#define	CMD_NAME	"Bankwatch"

static	HWND	bankWnd;

static	BOOL	ShowBanks, BigBanks, UseCRC;
static	WORD	Addr, DumpFrom, DumpTo;
static	BYTE	Data;
static	int	Count1, Count2, Count3;
static	DWORD	Checksums[256];
static	int	NumBanks;
static	BYTE	CHRbuffer[8][512], PRGbuffer[10][32];

static	HDC	BankDC;
static	HBITMAP	BankBMP;
static	RECT	BankRect;

#define	FONT_WIDTH	7
#define	FONT_HEIGHT	13

void	BankPercent (int percent)
{
	if (bankWnd == NULL)
		return;
	SendDlgItemMessage(bankWnd,IDC_BANK_PROGRESS,PBM_SETPOS,(WPARAM)percent,0);
	UpdateWindow(bankWnd);
}

void	RedrawBanks (void)
{
	int i, j;
	// set font
	int W = FONT_WIDTH, H = FONT_HEIGHT;
	int Y = 1;
	int Yp = 3;
	RECT rect;

	rect.left = 0;
	rect.right = BankRect.right - BankRect.left;
	rect.top = 0;
	rect.bottom = BankRect.bottom - BankRect.top;	// get size of 'bankinfo' box
	FillRect(BankDC, &rect, (HBRUSH)GetStockObject(WHITE_BRUSH));

	if (!ShowBanks)
		return;

	// draw CHR borders and labels
	MoveToEx(BankDC, 0*W, 2*H+Y, NULL);
	LineTo(BankDC, 5*W + (BigBanks ? 256 : 128), 2*H+Y);
	TextOut(BankDC, 0*W, 2*H, "0000", 4);

	MoveToEx(BankDC, 0*W, 3*H+Y, NULL);
	LineTo(BankDC, 5*W + (BigBanks ? 256 : 128), 3*H+Y);
	TextOut(BankDC, 0*W, 3*H, "0400", 4);

	MoveToEx(BankDC, 0*W, 4*H+Y, NULL);
	LineTo(BankDC, 5*W + (BigBanks ? 256 : 128), 4*H+Y);
	TextOut(BankDC, 0*W, 4*H, "0800", 4);

	MoveToEx(BankDC, 0*W, 5*H+Y, NULL);
	LineTo(BankDC, 5*W + (BigBanks ? 256 : 128), 5*H+Y);
	TextOut(BankDC, 0*W, 5*H, "0C00", 4);

	MoveToEx(BankDC, 0*W, 6*H+Y, NULL);
	LineTo(BankDC, 5*W + (BigBanks ? 256 : 128), 6*H+Y);
	TextOut(BankDC, 0*W, 6*H, "1000", 4);

	MoveToEx(BankDC, 0*W, 7*H+Y, NULL);
	LineTo(BankDC, 5*W + (BigBanks ? 256 : 128), 7*H+Y);
	TextOut(BankDC, 0*W, 7*H, "1400", 4);

	MoveToEx(BankDC, 0*W, 8*H+Y, NULL);
	LineTo(BankDC, 5*W + (BigBanks ? 256 : 128), 8*H+Y);
	TextOut(BankDC, 0*W, 8*H, "1800", 4);

	MoveToEx(BankDC, 0*W, 9*H+Y, NULL);
	LineTo(BankDC, 5*W + (BigBanks ? 256 : 128), 9*H+Y);
	TextOut(BankDC, 0*W, 9*H, "1C00", 4);

	MoveToEx(BankDC, 0*W, 10*H+Y, NULL);
	LineTo(BankDC, 5*W + (BigBanks ? 256 : 128), 10*H+Y);

	// draw PRG borders and labels

	MoveToEx(BankDC, 6*W + 256, 0*H+Y, NULL);
	LineTo(BankDC, 43*W + 256, 0*H+Y);
	TextOut(BankDC, 6*W + 256, 0*H, "6000", 4);

	MoveToEx(BankDC, 6*W + 256, 1*H+Y, NULL);
	LineTo(BankDC, 43*W + 256, 1*H+Y);
	if (BigBanks)
		TextOut(BankDC, 6*W + 256, 1*H, "7000", 4);

	MoveToEx(BankDC, 6*W + 256, 2*H+Y, NULL);
	LineTo(BankDC, 43*W + 256, 2*H+Y);
	TextOut(BankDC, 6*W + 256, 2*H, "8000", 4);

	MoveToEx(BankDC, 6*W + 256, 3*H+Y, NULL);
	LineTo(BankDC, 43*W + 256, 3*H+Y);
	if (BigBanks)
		TextOut(BankDC, 6*W + 256, 3*H, "9000", 4);

	MoveToEx(BankDC, 6*W + 256, 4*H+Y, NULL);
	LineTo(BankDC, 43*W + 256, 4*H+Y);
	TextOut(BankDC, 6*W + 256, 4*H, "A000", 4);

	MoveToEx(BankDC, 6*W + 256, 5*H+Y, NULL);
	LineTo(BankDC, 43*W + 256, 5*H+Y);
	if (BigBanks)
		TextOut(BankDC, 6*W + 256, 5*H, "B000", 4);

	MoveToEx(BankDC, 6*W + 256, 6*H+Y, NULL);
	LineTo(BankDC, 43*W + 256, 6*H+Y);
	TextOut(BankDC, 6*W + 256, 6*H, "C000", 4);

	MoveToEx(BankDC, 6*W + 256, 7*H+Y, NULL);
	LineTo(BankDC, 43*W + 256, 7*H+Y);
	if (BigBanks)
		TextOut(BankDC, 6*W + 256, 7*H, "D000", 4);

	MoveToEx(BankDC, 6*W + 256, 8*H+Y, NULL);
	LineTo(BankDC, 43*W + 256, 8*H+Y);
	TextOut(BankDC, 6*W + 256, 8*H, "E000", 4);

	MoveToEx(BankDC, 6*W + 256, 9*H+Y, NULL);
	LineTo(BankDC, 43*W + 256, 9*H+Y);
	if (BigBanks)
		TextOut(BankDC, 6*W + 256, 9*H, "F000", 4);

	MoveToEx(BankDC, 6*W + 256, 10*H+Y, NULL);
	LineTo(BankDC, 43*W + 256, 10*H+Y);

	// draw in the banks
	for (i = 0; i < 8; i++)
	{
		int numtiles = BigBanks ? 32 : 16;
		for (j = 0; j < numtiles; j++)
		{
			int x, y;
			BYTE *tiledata = &CHRbuffer[i][j * 16];
			for (y = 0; y < 8; y++)
			{
				for (x = 0; x < 8; x++)
				{
					const BYTE colors[4] = {0x00, 0x55, 0xAA, 0xFF};
					int pixel = (tiledata[0] & (0x80 >> x)) >> (7-x);
					pixel |= ((tiledata[8] & (0x80 >> x)) >> (7-x)) << 1;
					SetPixel(BankDC, 5*W + 8*j + x, (i+2)*H + y + Y + Yp, RGB(colors[pixel],colors[pixel],colors[pixel]));
				}
				tiledata++;
			}
		}
	}

	for (i = 0; i < 10; i++)
	{
		if (NumBanks)
		{
			int checksum = 0;
			char bankstr[33] = "BANK ";
			int banksfound = 0;

			if (UseCRC)
				checksum = PRGbuffer[i][0] | (PRGbuffer[i][1] << 8) | (PRGbuffer[i][2] << 16) | (PRGbuffer[i][3] << 24);
			else
			{
				for (j = 0; j < 32; j++)
					checksum += PRGbuffer[i][j];
			}

			for (j = 0; j < NumBanks; j++)
				if (Checksums[j] == checksum)
				{
					char bank[4];
					if (banksfound)
						sprintf(bank,",%02X",j);
					else	sprintf(bank,"%02X",j);
					strcat(bankstr,bank);
					if (banksfound == 8)
					{
						strcat(bankstr,",...");
						break;
					}
					banksfound++;
				}
			TextOut(BankDC, 11*W+256, i*H, bankstr, strlen(bankstr));
		}
		else if (UseCRC)
		{
			char crc[9];
			sprintf(crc,"%02X%02X%02X%02X",PRGbuffer[i][0],PRGbuffer[i][1],PRGbuffer[i][2],PRGbuffer[i][3]);
			TextOut(BankDC, 11*W+256, i*H, crc, 8);
		}
		else	TextOut(BankDC, 11*W+256, i*H, PRGbuffer[i], 32);
		if (!BigBanks)
			i++;
	}
	RedrawWindow(bankWnd,NULL,NULL,RDW_INVALIDATE);
}

void	GetBanks (void)
{
	BYTE mirror;
	int i, j;
	BYTE Cmd;
	if (!ShowBanks)
		return;

	if (BigBanks)
		Cmd = 0x04;
	else	Cmd = 0x03;
	if (!WriteByte(Cmd) || !WriteByte((BYTE)UseCRC))
	{
		EndDialog(bankWnd,FALSE);
		return;
	}

	for (i = 0; i < 8; i++)
	{
		for (j = 0; j < 256; j++)
			if (!ReadByte(&CHRbuffer[i][j]))
			{
				EndDialog(bankWnd,FALSE);
				return;
			}
		if (BigBanks)
			for (j = 256; j < 512; j++)
				if (!ReadByte(&CHRbuffer[i][j]))
				{
					EndDialog(bankWnd,FALSE);
					return;
				}
		BankPercent(i * 50 / 8);
	}

	BankPercent(50);

	for (i = 0; i < 10; i++)
	{
		for (j = 0; j < 32; j++)
			if (!ReadByte(&PRGbuffer[i][j]))
			{
				EndDialog(bankWnd,FALSE);
				return;
			}
		if (!BigBanks)
			i++;
		BankPercent(50 + 5 * i);
	}

	ReadByte(&mirror);
	CheckDlgButton(bankWnd,IDC_BANK_NT0,(mirror & 1) ? BST_CHECKED : BST_UNCHECKED);
	CheckDlgButton(bankWnd,IDC_BANK_NT1,(mirror & 2) ? BST_CHECKED : BST_UNCHECKED);
	CheckDlgButton(bankWnd,IDC_BANK_NT2,(mirror & 4) ? BST_CHECKED : BST_UNCHECKED);
	CheckDlgButton(bankWnd,IDC_BANK_NT3,(mirror & 8) ? BST_CHECKED : BST_UNCHECKED);

	BankPercent(0);
	RedrawBanks();
	InitPort();
}

LRESULT CALLBACK DLG_BankWatch(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	POINT wcl = {0, 0}, fontsize = {FONT_WIDTH, FONT_HEIGHT};
	RECT rect;
	HFONT font;

	PAINTSTRUCT ps;
	HDC hdc;
	switch (message)
	{
	case WM_INITDIALOG:
		bankWnd = hDlg;
		ShowBanks = FALSE;
		BigBanks = FALSE;
		UseCRC = FALSE;
		NumBanks = 0;

		Addr = 0x8000;
		Data = 0x00;
		SetDlgItemText(hDlg, IDC_BANK_ADDR, "8000");
		SetDlgItemText(hDlg, IDC_BANK_DATA, "00");

		DumpFrom = 0x8000;
		DumpTo = 0xFFFF;
		SetDlgItemText(hDlg, IDC_BANK_DUMPFROM, "8000");
		SetDlgItemText(hDlg, IDC_BANK_DUMPTO, "FFFF");

		SendDlgItemMessage(hDlg, IDC_BANK_PROGRESS, PBM_SETRANGE, 0, MAKELPARAM(0, 100));
		BankPercent(0);

		Count1 = Count2 = Count3 = 0;
		memset(CHRbuffer,0,sizeof(CHRbuffer));
		memset(PRGbuffer,0,sizeof(PRGbuffer));

		GetWindowRect(GetDlgItem(hDlg, IDC_BANK_INFO), &rect);	// get location of the 'bankinfo' box within screen
		ClientToScreen(hDlg, &wcl);				// get location of the dialog itself within screen
		BankRect.top = rect.top - wcl.y;
		BankRect.bottom = rect.bottom - wcl.y;
		BankRect.left = rect.left - wcl.x;
		BankRect.right = rect.right - wcl.x;			// get location of 'bankinfo' box within dialog


		hdc = GetWindowDC(GetDesktopWindow());
		BankDC = CreateCompatibleDC(hdc);
		BankBMP = CreateCompatibleBitmap(hdc, BankRect.right - BankRect.left, BankRect.bottom - BankRect.top);
		SelectObject(BankDC, BankBMP);
		
		DPtoLP(BankDC, &fontsize, 1);
		font = CreateFont(-fontsize.y, fontsize.x, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, OEM_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, FIXED_PITCH | FF_MODERN, NULL);
		SelectObject(BankDC, font);
		DeleteObject(font);

		SetBkMode(BankDC, TRANSPARENT);
		SelectObject(BankDC, (HPEN)GetStockObject(BLACK_PEN));

		ReleaseDC(GetDesktopWindow(), hdc);

		RedrawBanks();
		return TRUE;
		break;

	case WM_COMMAND:
		switch (LOWORD(wParam))
		{
		case IDC_BANK_ADDR:
		case IDC_BANK_DATA:
		{
			char a[8], b[8];
			int A, B;
			GetDlgItemText(hDlg,IDC_BANK_ADDR,a,8);
			GetDlgItemText(hDlg,IDC_BANK_DATA,b,8);
			if (!sscanf(a,"%X",&A))
			{
				EnableWindow(GetDlgItem(hDlg,IDC_BANK_WRITE),FALSE);
				EnableWindow(GetDlgItem(hDlg,IDC_BANK_READ),FALSE);
				EnableWindow(GetDlgItem(hDlg,IDC_BANK_RUN),FALSE);
			}
			else if (!sscanf(b,"%X",&B))
			{
				EnableWindow(GetDlgItem(hDlg,IDC_BANK_WRITE),FALSE);
				EnableWindow(GetDlgItem(hDlg,IDC_BANK_READ),TRUE);
				EnableWindow(GetDlgItem(hDlg,IDC_BANK_RUN),TRUE);
				Addr = A;
			}
			else
			{
				EnableWindow(GetDlgItem(hDlg,IDC_BANK_WRITE),TRUE);
				EnableWindow(GetDlgItem(hDlg,IDC_BANK_READ),TRUE);
				EnableWindow(GetDlgItem(hDlg,IDC_BANK_RUN),TRUE);
				Addr = A;
				Data = B;
			}
		}	break;

		case IDC_BANK_DUMPFROM:
		case IDC_BANK_DUMPTO:
		{
			char a[8], b[8];
			int A, B;
			GetDlgItemText(hDlg,IDC_BANK_DUMPFROM,a,8);
			GetDlgItemText(hDlg,IDC_BANK_DUMPTO,b,8);
			if (!sscanf(a,"%X",&A) || !sscanf(b,"%X",&B))
				EnableWindow(GetDlgItem(hDlg,IDC_BANK_DUMP),FALSE);
			else
			{
				EnableWindow(GetDlgItem(hDlg,IDC_BANK_DUMP),TRUE);
				DumpFrom = A;
				DumpTo = B;
			}
		}	break;

		case IDC_BANK_READ:
		{
			BYTE data;	// don't use the global "Data", or it'll affect what's behind the editbox
			char Info[64];
			if (!WriteByte(0x02) || !WriteByte((BYTE)(Addr & 0xFF)) || !WriteByte((BYTE)(Addr >> 8)) || !ReadByte(&data))
			{
				EndDialog(hDlg,FALSE);
				return FALSE;
			}
			sprintf(Info,"%04X\t%02X\tRD",Addr,data);
			SendDlgItemMessage(hDlg,IDC_BANK_HISTORY,LB_INSERTSTRING,0,(LPARAM)Info);
			GetBanks();
		}	break;

		case IDC_BANK_WRITE:
		{
			char Info[64];
			if (!WriteByte(0x01) || !WriteByte((BYTE)(Addr & 0xFF)) || !WriteByte((BYTE)(Addr >> 8)) || !WriteByte(Data) || !WriteByte(0x00) || !WriteByte(0x00))
			{
				EndDialog(hDlg,FALSE);
				return FALSE;
			}
			sprintf(Info,"%04X\t%02X\tWR",Addr,Data);
			SendDlgItemMessage(hDlg,IDC_BANK_HISTORY,LB_INSERTSTRING,0,(LPARAM)Info);
			GetBanks();
		}	break;

		case IDC_BANK_RUN:
		{
			OpenStatus(hDlg);
			StatusText("Resetting USB CopyNES...");
			ResetNES(RESET_COPYMODE);
			StatusText("Running code at address %04X...",Addr);
			if (!WriteCommand(0x7E,(BYTE)(Addr & 0xFF),(BYTE)(Addr >> 8),0x00,0xE7))
			{
				CloseStatus();
				EndDialog(hDlg,FALSE);
				return FALSE;
			}
			StatusText("Press OK to return to Bankwatch");
			StatusButton();
			// fall through
		}
		case IDC_BANK_RESET:
		{
			OpenStatus(hDlg);	// it's okay to attempt to re-open the dialog - it'll ignore it
			StatusText("Resetting USB CopyNES...");
			ResetNES(RESET_COPYMODE);
			StatusText("Loading plugin...");
			if (!LoadPlugin("bankwtch.bin"))
			{
				CloseStatus();
				EndDialog(hDlg,FALSE);
				return FALSE;
			}
			StatusText("Initializing plugin...");
			if (!RunCode())
			{
				CloseStatus();
				EndDialog(hDlg,FALSE);
				return FALSE;
			}
			CloseStatus();
		}	break;

		case IDC_BANK_CUST1:
			Count1++;
			SetDlgItemInt(hDlg,IDC_BANK_CNT1,Count1,FALSE);
			if (!WriteByte(0x06))
			{
				EndDialog(hDlg,FALSE);
				return FALSE;
			}
			break;
		case IDC_BANK_CUST2:
			Count2++;
			SetDlgItemInt(hDlg,IDC_BANK_CNT2,Count2,FALSE);
			if (!WriteByte(0x07))
			{
				EndDialog(hDlg,FALSE);
				return FALSE;
			}
			break;
		case IDC_BANK_CUST3:
			Count3++;
			SetDlgItemInt(hDlg,IDC_BANK_CNT3,Count3,FALSE);
			if (!WriteByte(0x08))
			{
				EndDialog(hDlg,FALSE);
				return FALSE;
			}
			break;

		case IDC_BANK_CNT1:
			Count1 = 0;
			SetDlgItemInt(hDlg,IDC_BANK_CNT1,Count1,FALSE);
			break;
		case IDC_BANK_CNT2:
			Count2 = 0;
			SetDlgItemInt(hDlg,IDC_BANK_CNT2,Count2,FALSE);
			break;
		case IDC_BANK_CNT3:
			Count3 = 0;
			SetDlgItemInt(hDlg,IDC_BANK_CNT3,Count3,FALSE);
			break;

		case IDC_BANK_DUMP:
		{
				BYTE a;
        
        			char filename[MAX_PATH];
			FILE *DUMP;
			int DumpLen = DumpTo - DumpFrom + 1;
			int i;
			if (!PromptFile(topHWnd,"Binary file(*.BIN)\0*.bin\0\0",filename,NULL,NULL,"Save data as?","bin",TRUE))
				break;
			OpenStatus(hDlg);
			StatusText("Dumping data from $%04X-$%04X (%04X bytes)", DumpFrom, DumpTo, DumpLen);
			if (!WriteByte(0x05) || !WriteByte((BYTE)(DumpFrom & 0xFF)) || !WriteByte((BYTE)(DumpFrom >> 8)) || !WriteByte((BYTE)(DumpLen & 0xFF)) || !WriteByte((BYTE)(DumpLen >> 8)))
			{
				CloseStatus();
				EndDialog(hDlg,FALSE);
				return FALSE;
			}
			DUMP = fopen(filename,"wb");
			StatusPercent(0);
			for (i = 0; i < DumpLen; i++)
			{

				if (!ReadByte(&a))
				{
					CloseStatus();
					EndDialog(hDlg,FALSE);
					return FALSE;
				}
				fwrite(&a,1,1,DUMP);
				if (!(i & 7))
					StatusPercent(100 * i / DumpLen);
			}
			
			//ReadByte(&a);   //read in last byte?
			InitPort();
			StatusPercent(100);
			StatusText("Data dumped successfully!");
			StatusOK();
			fclose(DUMP);
		}	break;

		case IDC_BANK_HISTORY:
		{
			int a, b;
			int line = SendDlgItemMessage(hDlg,IDC_BANK_HISTORY,LB_GETCURSEL,0,0);
			char buf[16];

			if (line == LB_ERR)
				break;

			SendDlgItemMessage(hDlg,IDC_BANK_HISTORY,LB_GETTEXT,line,(LPARAM)buf);
			buf[strlen(buf) - 3] = 0;
			sscanf(buf,"%X\t%X", &a, &b);
			sprintf(buf,"%04X", a);
			SetDlgItemText(hDlg, IDC_BANK_ADDR, buf);
			sprintf(buf,"%02X", b);
			SetDlgItemText(hDlg, IDC_BANK_DATA, buf);
		}	break;

		case IDC_BANK_CLRHIST:
			SendDlgItemMessage(hDlg, IDC_BANK_HISTORY, LB_RESETCONTENT, 0, 0);
			break;
		case IDC_BANK_LOAD:
		{
			BYTE numbanks;
			int i, j;
			OpenStatus(hDlg);

			StatusText("Retrieving bank information...");
			if (!WriteByte(0x09) || !ReadByte(&numbanks))
			{
				CloseStatus();
				EndDialog(hDlg,FALSE);
				return FALSE;
			}
			NumBanks = numbanks + 1;
			StatusText("%i banks found! Downloading checksums...", NumBanks);
			StatusPercent(0);
			for (i = 0; i < NumBanks; i++)
			{
				DWORD checksum = 0;
				if (!WriteByte(0x0A) || !WriteByte((BYTE)i))
				{
					CloseStatus();
					EndDialog(hDlg,FALSE);
					return FALSE;
				}
				if (UseCRC)
				{
					DWORD n;
					if (!ReadByte((BYTE *)&n + 0) || !ReadByte((BYTE *)&n + 1) || !ReadByte((BYTE *)&n + 2) || !ReadByte((BYTE *)&n + 3))
					{
						CloseStatus();
						EndDialog(hDlg,FALSE);
						return FALSE;
					}
					checksum = n;
					for (j = 0; j < 28; j++)
					{
						BYTE n;
						if (!ReadByte(&n))
						{
							CloseStatus();
							EndDialog(hDlg,FALSE);
							return FALSE;
						}
					}
				}
				else
				{
					for (j = 0; j < 32; j++)
					{
						BYTE n;
						if (!ReadByte(&n))
						{
							CloseStatus();
							EndDialog(hDlg,FALSE);
							return FALSE;
						}
						checksum += n;
					}
					checksum &= 0xFFFF;
				}
				Checksums[i] = checksum;
				StatusPercent(i * 100 / NumBanks);
			}
			StatusPercent(100);
			StatusText("Done!");
			StatusOK();
			GetBanks();
		}	break;

		case IDC_BANK_CLR:
			NumBanks = 0;
			GetBanks();
			break;
		case IDC_BANK_RECV:
		{
			char filename[MAX_PATH];
			FILE *DUMP;
			DWORD size = 0;
			int i;

			if (!PromptFile(topHWnd,"Binary file(*.BIN)\0*.bin\0\0",filename,NULL,NULL,"Save data as?","bin",TRUE))
				break;
			OpenStatus(hDlg);

			StatusText("Reading custom data from BankWatch plugin...");

			if (!WriteByte(0x0B) || !ReadByte((BYTE *)&size) || !ReadByte((BYTE *)&size + 1) || !ReadByte((BYTE *)&size + 2))
			{
				CloseStatus();
				EndDialog(hDlg,FALSE);
				return FALSE;
			}

			StatusText("Downloading %i bytes...", size);

			DUMP = fopen(filename,"wb");
			StatusPercent(0);
			for (i = 0; i < (signed)size; i++)
			{
				BYTE a;
				if (!ReadByte(&a))
				{
					CloseStatus();
					EndDialog(hDlg,FALSE);
					return FALSE;
				}
				fwrite(&a,1,1,DUMP);
				if (!(i & 7))
					StatusPercent(100 * i / size);
			}
			StatusPercent(100);
			fclose(DUMP);
			StatusText("Data dumped successfully!");
			StatusOK();
		}	break;

		case IDC_BANK_UPDATE:
			ShowBanks = (IsDlgButtonChecked(hDlg,IDC_BANK_UPDATE) == BST_CHECKED);
			GetBanks();
			break;
		case IDC_BANK_RES:
			BigBanks = (IsDlgButtonChecked(hDlg,IDC_BANK_RES) == BST_CHECKED);
			if (!BigBanks)
			{
				UseCRC = FALSE;
				CheckDlgButton(hDlg,IDC_BANK_CRC,BST_UNCHECKED);
			}
			GetBanks();
			break;
		case IDC_BANK_CRC:
			UseCRC = (IsDlgButtonChecked(hDlg,IDC_BANK_CRC) == BST_CHECKED);
			if (UseCRC)
			{
				BigBanks = TRUE;
				CheckDlgButton(hDlg,IDC_BANK_RES,BST_CHECKED);
			}
			GetBanks();
			break;
		case IDOK:
			EndDialog(hDlg,TRUE);
		}
		break;

	case WM_PAINT:
		hdc = BeginPaint(hDlg,&ps);
		BitBlt(hdc, BankRect.left, BankRect.top, BankRect.right - BankRect.left, BankRect.bottom - BankRect.top, BankDC, 0, 0, SRCCOPY);
		EndPaint(hDlg,&ps);
		break;

	case WM_CLOSE:
		EndDialog(hDlg,TRUE);
		return TRUE;
		break;

	case WM_DESTROY:
		DeleteDC(BankDC);
		DeleteObject(BankBMP);
		break;
	}
	return FALSE;
}


BOOL	CMD_BANKWATCH (void)
{
	BOOL status;
	OpenStatus(topHWnd);
	StatusText("Resetting USB CopyNES...");
	ResetNES(RESET_COPYMODE);
	StatusText("Loading plugin...");
	if (!LoadPlugin("bankwtch.bin"))
	{
		CloseStatus();
		return FALSE;
	}
	StatusText("Initializing plugin...");
	if (!RunCode())
	{
		CloseStatus();
		return FALSE;
	}
	Sleep(SLEEP_SHORT);
	CloseStatus();

	status = DialogBox(hInst,MAKEINTRESOURCE(IDD_BANKWATCH),topHWnd,DLG_BankWatch);
	ResetNES(RESET_COPYMODE);
	return status;
}
