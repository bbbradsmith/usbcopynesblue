#include "StdAfx.h"

#define MAX_LOADSTRING 100

// Global Variables:
HINSTANCE hInst;        // current instance
HWND	topHWnd = NULL; // main window

TCHAR szTitle[MAX_LOADSTRING];       // The application name
TCHAR szWindowClass[MAX_LOADSTRING]; // The title bar text

// Foward declarations of functions included in this code module:
ATOM                MyRegisterClass(HINSTANCE hInstance);
BOOL                InitInstance(HINSTANCE, int);
LRESULT CALLBACK    CopyNES_Menu(HWND, UINT, WPARAM, LPARAM);

int APIENTRY WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	MSG msg;

	// Initialize global strings
	LoadString(hInstance, IDS_APP_TITLE, szTitle, MAX_LOADSTRING);
	LoadString(hInstance, IDS_APP_TITLE, szWindowClass, MAX_LOADSTRING);

	// Perform application initialization:
	if (!InitInstance (hInstance, nCmdShow)) 
		return FALSE;

	// Main message loop:
	while (GetMessage(&msg, NULL, 0, 0)) 
	{
		if (!IsDialogMessage(DlgStatus,&msg) && !IsDialogMessage(topHWnd,&msg))
		{
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
	}

	return msg.wParam;
}

//
//   FUNCTION: InitInstance(HANDLE, int)
//
//   PURPOSE: Saves instance handle and creates main window
//
//   COMMENTS:
//
//        In this function, we save the instance handle in a global variable and
//        create and display the main program window.
//
BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{
	hInst = hInstance; // Store instance handle in our global variable

	topHWnd = CreateDialog(hInst,MAKEINTRESOURCE(IDD_MAINMENU),NULL,CopyNES_Menu);
	if (!topHWnd)
		return FALSE;
	return TRUE;
}

BOOL    Startup (void);
BOOL    Shutdown (void);

BOOL    CMD_MAKENES (void);
BOOL    CMD_MAKEUNIF (void);
BOOL    CMD_SPLITNES (void);
BOOL    CMD_SPLITUNIF (void);

BOOL    CMD_BREAKBANK (void);
BOOL    CMD_DISASM (void);
BOOL    CMD_OPTIONS (void);
BOOL    CMD_NESINFO (void);

BOOL    CMD_PLAYCART (void);
BOOL    CMD_RAMCART (void);
BOOL    CMD_PLAYNSF (void);
BOOL    CMD_REGPLAY (void);

BOOL    CMD_DUMPCART (void);
BOOL    CMD_WRITEWRAM (void);
BOOL    CMD_RUNPLUG (void);
BOOL    CMD_FIXGAR (void);

BOOL    CMD_BANKWATCH (void);
BOOL    CMD_MICROBUG (void);
BOOL    CMD_VRC7REGS (void);
BOOL    CMD_RECONNECT (void);

BOOL    CMD_PLAYLOG (void);

void EnableMenus (HWND hDlg)
{
	if (HWVer == 0)
	{
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_MAKENES),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_MAKEUNIF),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_SPLITNES),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_SPLITUNIF),TRUE);

		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_BREAKBANK),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_DISASM),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_OPTIONS),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_NESINFO),FALSE);

		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_PLAYCART),FALSE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_RAMCART),FALSE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_PLAYNSF),FALSE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_REGPLAY),FALSE);

		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_DUMPCART),FALSE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_WRITEWRAM),FALSE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_RUNPLUG),FALSE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_FIXGAR),FALSE);

		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_BANKWATCH),FALSE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_MICROBUG),FALSE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_VRC7REGS),FALSE);

		if(ParPort == 0)
		{
			EnableWindow(GetDlgItem(hDlg,IDC_MAIN_RECONNECT),FALSE);
		}	//Only disable this option when we are in full offline mode, and not just disconnected from selected interface.
		else
		{
			EnableWindow(GetDlgItem(hDlg,IDC_MAIN_RECONNECT),TRUE);
		}
		
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_PLAYLOG),FALSE);
		// disable all "online" options
	}
	else if (HWVer == 1)
	{	// disable MicroBug
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_MAKENES),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_MAKEUNIF),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_SPLITNES),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_SPLITUNIF),TRUE);

		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_BREAKBANK),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_DISASM),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_OPTIONS),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_NESINFO),TRUE);

		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_PLAYCART),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_RAMCART),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_PLAYNSF),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_REGPLAY),TRUE);

		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_DUMPCART),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_WRITEWRAM),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_RUNPLUG),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_FIXGAR),TRUE);

		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_BANKWATCH),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_MICROBUG),FALSE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_VRC7REGS),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_RECONNECT),TRUE);

		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_PLAYLOG),TRUE);
	}
	else
	{	// enable everything
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_MAKENES),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_MAKEUNIF),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_SPLITNES),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_SPLITUNIF),TRUE);

		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_BREAKBANK),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_DISASM),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_OPTIONS),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_NESINFO),TRUE);

		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_PLAYCART),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_RAMCART),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_PLAYNSF),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_REGPLAY),TRUE);

		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_DUMPCART),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_WRITEWRAM),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_RUNPLUG),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_FIXGAR),TRUE);

		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_BANKWATCH),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_MICROBUG),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_VRC7REGS),TRUE);
		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_RECONNECT),TRUE);

		EnableWindow(GetDlgItem(hDlg,IDC_MAIN_PLAYLOG),TRUE);

		if ((ParPort != -1) && (HWVer > 3))
			MessageBox(topHWnd,"Unrecognized CopyNES BIOS version detected!\nPlease check for an updated version of the client software!", "CopyNES Blue", MB_OK | MB_ICONERROR);
		if ((ParPort == -1) && (HWVer < 4))
			MessageBox(topHWnd,"Unrecognized USB CopyNES BIOS version detected!\nPlease check for an updated version of the client software!", "CopyNES Blue", MB_OK | MB_ICONERROR);
		if(HWVer == 255)
			MessageBox(topHWnd,"USB CopyNES connect failed!  Try reconnecting.", "CopyNES Blue", MB_OK | MB_ICONERROR);
	}
}

LRESULT CALLBACK CopyNES_Menu(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	BOOL success = TRUE;
	switch (message)
	{
	case WM_INITDIALOG:
		if (!Startup())
		{
			Shutdown();
			DestroyWindow(hDlg);
			return FALSE;
		}
		ShowWindow(hDlg,SW_SHOWNORMAL);
		EnableMenus(hDlg);
		return TRUE;
		break;
	case WM_COMMAND:
		switch (LOWORD(wParam))
		{
		case IDC_MAIN_MAKENES:
			success = CMD_MAKENES();
			break;
		case IDC_MAIN_MAKEUNIF:
			success = CMD_MAKEUNIF();
			break;
		case IDC_MAIN_SPLITNES:
			success = CMD_SPLITNES();
			break;
		case IDC_MAIN_SPLITUNIF:
			success = CMD_SPLITUNIF();
			break;

		case IDC_MAIN_BREAKBANK:
			success = CMD_BREAKBANK();
			break;
		case IDC_MAIN_DISASM:
			success = CMD_DISASM();
			break;
		case IDC_MAIN_OPTIONS:
			success = CMD_OPTIONS();
			break;
		case IDC_MAIN_NESINFO:
			InitPort();
			success = CMD_NESINFO();
			break;

		case IDC_MAIN_PLAYCART:
			InitPort();
			success = CMD_PLAYCART();
			break;
		case IDC_MAIN_RAMCART:
			InitPort();
			success = CMD_RAMCART();
			break;
		case IDC_MAIN_PLAYNSF:
			InitPort();
			success = CMD_PLAYNSF();
			break;
		case IDC_MAIN_REGPLAY:
			InitPort();
			success = CMD_REGPLAY();
			break;

		case IDC_MAIN_DUMPCART:
			InitPort();
			success = CMD_DUMPCART();
			break;
		case IDC_MAIN_WRITEWRAM:
			InitPort();
			success = CMD_WRITEWRAM();
			break;
		case IDC_MAIN_RUNPLUG:
			InitPort();
			success = CMD_RUNPLUG();
			break;
		case IDC_MAIN_FIXGAR:
			InitPort();
			success = CMD_FIXGAR();
			break;

		case IDC_MAIN_BANKWATCH:
			InitPort();
			success = CMD_BANKWATCH();
			break;
		case IDC_MAIN_MICROBUG:
			InitPort();
			success = CMD_MICROBUG();
			break;
		case IDC_MAIN_VRC7REGS:
			InitPort();
			success = CMD_VRC7REGS();
			break;
		case IDC_MAIN_RECONNECT:
			success = CMD_RECONNECT();
			EnableMenus(hDlg);
			break;

		case IDC_MAIN_PLAYLOG:
			InitPort();
			success = CMD_PLAYLOG();
			break;
		}
		if (!success)
			MessageBox(topHWnd,"An error occurred during the previous operation!","USB CopyNES",MB_OK | MB_ICONERROR);
		return TRUE;
		break;
	case WM_CLOSE:
		Shutdown();
		DestroyWindow(hDlg);
		return 0;
		break;
	case WM_DESTROY:
		PostQuitMessage(0);
		return 0;
		break;
	}
	return FALSE;
}