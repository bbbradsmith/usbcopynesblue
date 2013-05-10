#include "StdAfx.h"
#include <commctrl.h>

/* Status dialog */
static	BOOL StatButton;
LRESULT CALLBACK DLG_Status (HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	switch (message)
	{
	case WM_INITDIALOG:
		SendDlgItemMessage(hDlg,IDC_STATUS_GRAPH,PBM_SETRANGE,0,MAKELPARAM(0,100));
		SendDlgItemMessage(hDlg,IDC_STATUS_GRAPH,PBM_SETPOS,(WPARAM)0,0);
		EnableWindow(GetDlgItem(hDlg,IDC_STATUS_BUTTON),FALSE);
		ShowWindow(hDlg,SW_SHOWNORMAL);
		return TRUE;			break;
	case WM_COMMAND:
		if (LOWORD(wParam) == IDC_STATUS_BUTTON)
		{
			StatButton = TRUE;
			return 0;
		}
		return TRUE;
	}
	return FALSE;
}

HWND	DlgStatus = NULL;
void	CloseStatus (void)
{
	if (DlgStatus == NULL)
		return;
	DestroyWindow(DlgStatus);
	DlgStatus = NULL;
}

void	OpenStatus (HWND hWnd)
{
	if (DlgStatus != NULL)
		return;
	DlgStatus = CreateDialog(hInst,MAKEINTRESOURCE(IDD_STATUS),hWnd,DLG_Status);
	if (DlgStatus != NULL)
		UpdateWindow(DlgStatus);
}

void	__cdecl	StatusText (char *text, ...)
{
	static char txt[1024];
	va_list marker;

	if (DlgStatus == NULL)
		return;
	va_start(marker,text);
	_vsnprintf(txt,1024,text,marker);
	va_end(marker);

	SendDlgItemMessage(DlgStatus,IDC_STATUS_TEXT,LB_ADDSTRING,0,(LPARAM)(LPCTSTR)txt);
	SendDlgItemMessage(DlgStatus,IDC_STATUS_TEXT,LB_SETTOPINDEX,SendDlgItemMessage(DlgStatus,IDC_STATUS_TEXT,LB_GETCOUNT,0,0) - 1,0);
	UpdateWindow(DlgStatus);

	// for debugging
	OutputDebugString("Status: ");
	OutputDebugString(txt);
	OutputDebugString("\n");
}

void	StatusPercent (int percent)
{
	if (DlgStatus == NULL)
		return;
	SendDlgItemMessage(DlgStatus,IDC_STATUS_GRAPH,PBM_SETPOS,(WPARAM)percent,0);
	UpdateWindow(DlgStatus);
}

void	StatusButton (void)
{
	if (DlgStatus == NULL)
		return;
	StatButton = FALSE;
	EnableWindow(GetDlgItem(DlgStatus,IDC_STATUS_BUTTON),TRUE);
	SetFocus(GetDlgItem(DlgStatus,IDC_STATUS_BUTTON)); 

	while (!StatButton)
	{
		MSG msg;
		while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) 
		{
			if (!IsDialogMessage(DlgStatus,&msg) && !IsDialogMessage(topHWnd,&msg))
			{
				TranslateMessage(&msg);
				DispatchMessage(&msg);
			}
		}
		Sleep(10);
	}
	EnableWindow(GetDlgItem(DlgStatus,IDC_STATUS_BUTTON),FALSE);
}

void	StatusButtonAsync (BOOL enabled)
{
	if (DlgStatus == NULL)
		return;
	StatButton = FALSE;
	EnableWindow(GetDlgItem(DlgStatus,IDC_STATUS_BUTTON),enabled);
	if (enabled)
		SetFocus(GetDlgItem(DlgStatus,IDC_STATUS_BUTTON)); 
}

BOOL	StatusButtonPressed (void)
{
	MSG msg;
	if (DlgStatus == NULL)
		return FALSE;
	while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) 
	{
		if (!IsDialogMessage(DlgStatus,&msg) && !IsDialogMessage(topHWnd,&msg))
		{
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
	}
	Sleep(10);
	
	if (StatButton)
		EnableWindow(GetDlgItem(DlgStatus,IDC_STATUS_BUTTON),FALSE);
	return StatButton;
}

void	StatusOK (void)
{
	StatusButton();
	CloseStatus();
}

/* Text prompt */

char	*PromptTitle;
char	PromptResult[1024];
LRESULT CALLBACK DLG_Prompt(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	switch (message)
	{
	case WM_INITDIALOG:
		SetDlgItemText(hDlg,IDC_PROMPT_TITLE,PromptTitle);
		return TRUE;			break;
	case WM_COMMAND:
		switch (LOWORD(wParam))
		{
		case IDOK:
			GetDlgItemText(hDlg,IDC_PROMPT_DATA,PromptResult,1024);
			if (strlen(PromptResult))
			{
				EndDialog(hDlg,1);
				return TRUE;	break;
			}
		case IDCANCEL:	// else fall through
			EndDialog(hDlg,-1);
			return TRUE;		break;
		}
		break;
	case WM_CLOSE:
		EndDialog(hDlg,-1);
		return TRUE;		break;
	}
	return FALSE;
}
BOOL	Prompt (HWND hWnd)
{
	return (DialogBox(hInst,MAKEINTRESOURCE(IDD_GENERICPROMPT),hWnd,DLG_Prompt) == 1);
}
BOOL	PromptLong (HWND hWnd)
{
	return (DialogBox(hInst,MAKEINTRESOURCE(IDD_GENERICPROMPTLONG),hWnd,DLG_Prompt) == 1);
}

/* File prompt */

static	OPENFILENAME	ofn;
BOOL	PromptFile (HWND hWnd, char *Filter, char *FilePath, char *FileName, char *InitDir, char *Title, char *DefExt, BOOL Save)
{
	if (FilePath)
		*FilePath = 0;
	if (FileName)
		*FileName = 0;
	memset(&ofn,0,sizeof(ofn));
	ofn.lStructSize       = sizeof(OPENFILENAME);
	ofn.hwndOwner         = hWnd;
	ofn.hInstance         = hInst;
	ofn.lpstrFilter       = Filter;
	ofn.lpstrCustomFilter = NULL;
	ofn.nMaxCustFilter    = 0;
	ofn.nFilterIndex      = 1;
	ofn.lpstrFile         = FilePath;
	ofn.nMaxFile          = MAX_PATH;
	ofn.lpstrFileTitle    = FileName;
	ofn.nMaxFileTitle     = MAX_PATH;
	ofn.lpstrInitialDir   = InitDir;
	ofn.lpstrTitle        = Title;
	ofn.Flags             = OFN_FILEMUSTEXIST;
	ofn.nFileOffset       = 0;
	ofn.nFileExtension    = 0;
	ofn.lpstrDefExt       = DefExt;
	ofn.lCustData         = 0;
	ofn.lpfnHook          = NULL;
	ofn.lpTemplateName    = NULL;

	if (Save)
		return GetSaveFileName(&ofn);
	else	return GetOpenFileName(&ofn);
}

/* Board Name Prompt */

LRESULT CALLBACK DLG_SelectPlugin(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	static int curcat = 0, curplug = 0;
	static int lastcat = 0, lastplug = 0;
	static PCategory category;
	static int Type;
	char desc[1024];

	int i;
	switch (message)
	{
	case WM_INITDIALOG:
		Type = (int)lParam;

		for (i = 0; Plugins[i] != NULL; i++)
		{
			if (Plugins[i]->type == Type)
				SendDlgItemMessage(hDlg,IDC_PLUGIN_CATEGORY,LB_ADDSTRING,0,(LPARAM)(LPCTSTR)Plugins[i]->desc);
			else	SendDlgItemMessage(hDlg,IDC_PLUGIN_CATEGORY,LB_ADDSTRING,0,(LPARAM)(LPCTSTR)"--------");
		}

		if (Type == PLUG_STD)
			i = 0;
		else
		{
			for (i = 0; Plugins[i] != NULL; i++)
				if (Plugins[i]->type == Type)
					break;
			if (Plugins[i] == NULL)
			{
				MessageBox(hDlg, "Unable to locate category - please update MAPPERS.DAT!", "Plugin", MB_OK | MB_ICONERROR);
				EndDialog(hDlg,(INT_PTR)NULL);
				return FALSE;
			}
			EnableWindow(GetDlgItem(hDlg,IDC_PLUGIN_CATEGORY),FALSE);
		}

		if (Plugins[i]->type == Plugins[lastcat]->type)
		{
			curcat = lastcat;
			curplug = lastplug;
		}
		else
		{
			curcat = i;
			curplug = 0;
		}
		category = Plugins[curcat];

		SendDlgItemMessage(hDlg,IDC_PLUGIN_CATEGORY,LB_SETCURSEL,curcat,0);

		for (i = 0; category->list[i] != NULL; i++)
			SendDlgItemMessage(hDlg,IDC_PLUGIN_LIST,LB_ADDSTRING,0,(LPARAM)(LPCTSTR)category->list[i]->name);

		SendDlgItemMessage(hDlg,IDC_PLUGIN_LIST,LB_SETCURSEL,curplug,0);
		sprintf(desc, "%s (%i)", category->list[curplug]->desc, category->list[curplug]->num);
		SetDlgItemText(hDlg,IDC_PLUGIN_DESC,desc);

		return TRUE;			break;
	case WM_COMMAND:
		if (HIWORD(wParam) == LBN_SELCHANGE)
		{
			if (LOWORD(wParam) == IDC_PLUGIN_CATEGORY)
			{
				if (Type != PLUG_STD)
					break;	// impossible - cannot switch categories
				i = SendDlgItemMessage(hDlg,IDC_PLUGIN_CATEGORY,LB_GETCURSEL,0,0);
				if (i == curcat)
					break;	// didn't actually change
				while (Plugins[i]->type != PLUG_STD)
				{	// switch to next category
					i++;
					if (Plugins[i] == NULL)
						i = 0;
				}
				curcat = i;
				curplug = 0;
				SendDlgItemMessage(hDlg,IDC_PLUGIN_CATEGORY,LB_SETCURSEL,curcat,0);	// update selection, in case it changed
				SendDlgItemMessage(hDlg,IDC_PLUGIN_LIST,LB_RESETCONTENT,0,0);
				category = Plugins[curcat];
				for (i = 0; category->list[i] != NULL; i++)
					SendDlgItemMessage(hDlg,IDC_PLUGIN_LIST,LB_ADDSTRING,0,(LPARAM)(LPCTSTR)category->list[i]->name);
				SendDlgItemMessage(hDlg,IDC_PLUGIN_LIST,LB_SETCURSEL,curplug,0);
				sprintf(desc, "%s (%i)", category->list[curplug]->desc, category->list[curplug]->num);
				SetDlgItemText(hDlg,IDC_PLUGIN_DESC,desc);
			}
			else if (LOWORD(wParam) == IDC_PLUGIN_LIST)
			{
				curplug = SendDlgItemMessage(hDlg,IDC_PLUGIN_LIST,LB_GETCURSEL,0,0);
				sprintf(desc, "%s (%i)", category->list[curplug]->desc, category->list[curplug]->num);
				SetDlgItemText(hDlg,IDC_PLUGIN_DESC,desc);
			}
		}
		if ((LOWORD(wParam) == IDOK) || ((HIWORD(wParam) == LBN_DBLCLK) && (LOWORD(wParam) == IDC_PLUGIN_LIST)))
		{
			i = SendDlgItemMessage(hDlg,IDC_PLUGIN_LIST,LB_GETCURSEL,0,0);
			if (i == LB_ERR)
				MessageBox(hDlg,"No plugin selected!","USB CopyNES",MB_OK | MB_ICONERROR);
			else
			{
				lastcat = curcat;
				lastplug = curplug;
				EndDialog(hDlg,(INT_PTR)category->list[i]);
			}
			return TRUE;		break;
		}
		else if (LOWORD(wParam) == IDCANCEL)
		{
			EndDialog(hDlg,(INT_PTR)NULL);
			return TRUE;		break;
		}				break;
	case WM_CLOSE:
		EndDialog(hDlg,(INT_PTR)NULL);
		return TRUE;			break;
	}
	return FALSE;
}

static char custplug_name[1024] = "CUSTOM";
static char custplug_file[1024] = "custom.bin";
static char custplug_desc[1024] = "User-Defined Mapper";
static TPlugin custplug = {custplug_name, custplug_file, 998, custplug_desc};

PPlugin	PromptPlugin (int Type)
{
	char filepath[MAX_PATH];
	PPlugin result = (PPlugin)DialogBoxParam(hInst,MAKEINTRESOURCE(IDD_SELECTPLUGIN),topHWnd,DLG_SelectPlugin,(LPARAM)Type);
	if (result == NULL)
		return NULL;

	if (result->num != 998)
		return result;

	PromptTitle = "Specify iNES mapper number (cancel for none):\r\n(-1 to skip .NES, 999 to skip .NES and .UNIF)";
	if (Prompt(topHWnd))
		custplug.num = atoi(PromptResult);
	else	custplug.num = -1;

	if (custplug.num != 999)
	{
		PromptTitle = "Specify UNIF board name (cancel for none):";
		if (Prompt(topHWnd))
			strcpy(custplug.name,PromptResult);
		else if (custplug.num == -1)
			custplug.num = 999;
	}

	while (1)
	{
		if (!PromptFile(topHWnd,"USB CopyNES Plugins (*.bin)\0*.bin\0\0\0\0", filepath, custplug.file, Path_PLUG, "Select a plugin (must be in Plugins path)", "bin", FALSE))
			return NULL;
		if (strnicmp(Path_PLUG, filepath, strlen(Path_PLUG)))
			MessageBox(topHWnd,"Selected file is not located in Plugins directory!","Select Plugin", MB_OK | MB_ICONERROR);
		else	break;
	}
	return &custplug;
}
