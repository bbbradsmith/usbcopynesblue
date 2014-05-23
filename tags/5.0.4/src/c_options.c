#include "StdAfx.h"
#include <shlobj.h>
#define	CMD_NAME	"Options"

// This MUST match the "USB" setting below
#define PORT_USB 5

int ParPort = -1;
int ParAddr;
int ParECP;

static	void	PromptForDirectory (HWND hDlg, const char *pathvar, int dlgitem)
{
	BROWSEINFO dirprompt;
	char dirName[MAX_PATH];
	ITEMIDLIST *idlist = NULL;
	
  IMalloc *pMalloc;
	if (SHGetMalloc(&pMalloc) != NOERROR)
		return;
	strcpy(dirName, pathvar);
	dirprompt.hwndOwner = hDlg;
	dirprompt.pidlRoot = NULL;
	dirprompt.pszDisplayName = dirName;
	dirprompt.lpszTitle = "Choose a directory...";
	dirprompt.ulFlags = BIF_EDITBOX | BIF_RETURNONLYFSDIRS;
	dirprompt.lpfn = NULL;
	dirprompt.lParam = 0;
	dirprompt.iImage = 0;
	if ((idlist = SHBrowseForFolder(&dirprompt)) == NULL)
		return;
	if (!SHGetPathFromIDList(idlist,dirName))
		return;
	SetDlgItemText(hDlg,dlgitem,dirName);
	pMalloc->lpVtbl->Free(pMalloc,idlist);
	pMalloc->lpVtbl->Release(pMalloc);	
}
static	LRESULT CALLBACK DLG_Options(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	char tmpstr[16];
	int newPort, newAddr, newECP;
	switch (message)
	{
	case WM_INITDIALOG:
		SetDlgItemText(hDlg,IDC_CONFIG_PRGDIR,Path_PRG);
		SetDlgItemText(hDlg,IDC_CONFIG_CHRDIR,Path_CHR);
		SetDlgItemText(hDlg,IDC_CONFIG_WRAMDIR,Path_WRAM);
		SetDlgItemText(hDlg,IDC_CONFIG_NESDIR,Path_NES);
		SetDlgItemText(hDlg,IDC_CONFIG_CRCDIR,Path_CRC);
		SetDlgItemText(hDlg,IDC_CONFIG_NSFDIR,Path_NSF);
		SetDlgItemText(hDlg,IDC_CONFIG_PLUGDIR,Path_PLUG);
		CheckDlgButton(hDlg,IDC_CONFIG_SAVECRC,(SaveCRC == 1) ? BST_CHECKED : BST_UNCHECKED);
		CheckDlgButton(hDlg,IDC_CONFIG_SAVEPARTS,(SaveFiles == 1) ? BST_CHECKED : BST_UNCHECKED);
		CheckDlgButton(hDlg,IDC_CONFIG_MAKEUNIF,(MakeUnif == 1) ? BST_CHECKED : BST_UNCHECKED);
		SendDlgItemMessage(hDlg,IDC_CONFIG_PORT,CB_ADDSTRING,0,(LPARAM)"Offline");
		SendDlgItemMessage(hDlg,IDC_CONFIG_PORT,CB_ADDSTRING,0,(LPARAM)"LPT1");
		SendDlgItemMessage(hDlg,IDC_CONFIG_PORT,CB_ADDSTRING,0,(LPARAM)"LPT2");
		SendDlgItemMessage(hDlg,IDC_CONFIG_PORT,CB_ADDSTRING,0,(LPARAM)"LPT3");
		SendDlgItemMessage(hDlg,IDC_CONFIG_PORT,CB_ADDSTRING,0,(LPARAM)"Other");
		SendDlgItemMessage(hDlg,IDC_CONFIG_PORT,CB_ADDSTRING,0,(LPARAM)"USB");
		if (ParPort == -1)
		{
			EnableWindow(GetDlgItem(hDlg,IDC_CONFIG_ADDR), FALSE);
			EnableWindow(GetDlgItem(hDlg,IDC_CONFIG_ECP), FALSE);
			SendDlgItemMessage(hDlg,IDC_CONFIG_PORT,CB_SETCURSEL,PORT_USB,0);
		}
		else
		{
			EnableWindow(GetDlgItem(hDlg,IDC_CONFIG_ADDR), TRUE);
			EnableWindow(GetDlgItem(hDlg,IDC_CONFIG_ECP), TRUE);
			SendDlgItemMessage(hDlg,IDC_CONFIG_PORT,CB_SETCURSEL,ParPort,0);
			sprintf(tmpstr,"%X",ParAddr);
			SetDlgItemText(hDlg,IDC_CONFIG_ADDR,tmpstr);
			sprintf(tmpstr,"%X",ParECP);
			SetDlgItemText(hDlg,IDC_CONFIG_ECP,tmpstr);
		}
		return TRUE;			break;
	case WM_COMMAND:
		switch (LOWORD(wParam))
		{
		case IDC_CONFIG_PRGBUTTON:	PromptForDirectory(hDlg,Path_PRG,IDC_CONFIG_PRGDIR);	break;
		case IDC_CONFIG_CHRBUTTON:	PromptForDirectory(hDlg,Path_CHR,IDC_CONFIG_CHRDIR);	break;
		case IDC_CONFIG_WRAMBUTTON:	PromptForDirectory(hDlg,Path_WRAM,IDC_CONFIG_WRAMDIR);	break;
		case IDC_CONFIG_NESBUTTON:	PromptForDirectory(hDlg,Path_NES,IDC_CONFIG_NESDIR);	break;
		case IDC_CONFIG_CRCBUTTON:	PromptForDirectory(hDlg,Path_CRC,IDC_CONFIG_CRCDIR);	break;
		case IDC_CONFIG_NSFBUTTON:	PromptForDirectory(hDlg,Path_NSF,IDC_CONFIG_NSFDIR);	break;
		case IDC_CONFIG_PLUGBUTTON:	PromptForDirectory(hDlg,Path_PLUG,IDC_CONFIG_PLUGDIR);	break;
		case IDC_CONFIG_PORT:
			newPort = SendDlgItemMessage(hDlg,IDC_CONFIG_PORT,CB_GETCURSEL,0,0);
			newAddr = 0;
			newECP = 0;
			if (newPort == PORT_USB)
			{
				EnableWindow(GetDlgItem(hDlg,IDC_CONFIG_ADDR), FALSE);
				EnableWindow(GetDlgItem(hDlg,IDC_CONFIG_ECP), FALSE);
			}
			else
			{
				EnableWindow(GetDlgItem(hDlg,IDC_CONFIG_ADDR), TRUE);
				EnableWindow(GetDlgItem(hDlg,IDC_CONFIG_ECP), TRUE);
			}
			if (newPort == 1)
			{
				newAddr = 0x378;
				newECP = 0x400;
			}
			if (newPort == 2)
			{
				newAddr = 0x278;
				newECP = 0x400;
			}
			if (newPort == 3)
			{
				newAddr = 0x3BC;
				newECP = 0x400;
			}
			if (newAddr)
			{
				sprintf(tmpstr,"%X",newAddr);
				SetDlgItemText(hDlg,IDC_CONFIG_ADDR,tmpstr);
			}
			if (newECP)
			{
				sprintf(tmpstr,"%X",newECP);
				SetDlgItemText(hDlg,IDC_CONFIG_ECP,tmpstr);
			}
			break;
		case IDOK:
			GetDlgItemText(hDlg,IDC_CONFIG_PRGDIR,Path_PRG,MAX_PATH);	addSlash(Path_PRG);
			GetDlgItemText(hDlg,IDC_CONFIG_CHRDIR,Path_CHR,MAX_PATH);	addSlash(Path_CHR);
			GetDlgItemText(hDlg,IDC_CONFIG_WRAMDIR,Path_WRAM,MAX_PATH);	addSlash(Path_WRAM);
			GetDlgItemText(hDlg,IDC_CONFIG_NESDIR,Path_NES,MAX_PATH);	addSlash(Path_NES);
			GetDlgItemText(hDlg,IDC_CONFIG_CRCDIR,Path_CRC,MAX_PATH);	addSlash(Path_CRC);
			GetDlgItemText(hDlg,IDC_CONFIG_NSFDIR,Path_NSF,MAX_PATH);	addSlash(Path_NSF);
			GetDlgItemText(hDlg,IDC_CONFIG_PLUGDIR,Path_PLUG,MAX_PATH);	addSlash(Path_PLUG);
			SaveCRC = (IsDlgButtonChecked(hDlg,IDC_CONFIG_SAVECRC) == BST_CHECKED) ? 1 : 0;
			SaveFiles = (IsDlgButtonChecked(hDlg,IDC_CONFIG_SAVEPARTS) == BST_CHECKED) ? 1 : 0;
			MakeUnif = (IsDlgButtonChecked(hDlg,IDC_CONFIG_MAKEUNIF) == BST_CHECKED) ? 1 : 0;

			newPort = SendDlgItemMessage(hDlg,IDC_CONFIG_PORT,CB_GETCURSEL,0,0);

			if (newPort == PORT_USB)
				newPort = -1;
			GetDlgItemText(hDlg,IDC_CONFIG_ADDR,tmpstr,16);
			sscanf(tmpstr,"%X",&newAddr);
			GetDlgItemText(hDlg,IDC_CONFIG_ECP,tmpstr,16);
			sscanf(tmpstr,"%X",&newECP);
			if ((newPort != ParPort) || (newAddr != ParAddr) || (newECP != ParECP))
			{
				extern void EnableMenus (HWND);
				extern int FindVersion (void);
				ClosePort();
				ParPort = newPort;
				ParAddr = newAddr;
				ParECP = newECP;
				if (OpenPort(ParPort, ParAddr, ParECP))
				{
					if (ParPort != -1)
						InitPort();
					ResetNES(RESET_COPYMODE);
					HWVer = FindVersion();
				}
				else	HWVer = 0;
				EnableMenus(topHWnd);
			}

			WriteConfig();
			// fall through
		case IDCANCEL:	EndDialog(hDlg,-1);	break;
		}				break;
	case WM_CLOSE:
		EndDialog(hDlg,-1);
		return TRUE;			break;
	}
	return FALSE;
}
BOOL	CMD_OPTIONS (void)
{
	DialogBox(hInst,MAKEINTRESOURCE(IDD_OPTIONS),topHWnd,DLG_Options);
	return TRUE;
}
