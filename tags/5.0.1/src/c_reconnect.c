#include "StdAfx.h"
#define	CMD_NAME	"USB Reconnect"

int	FindVersion (void); // defined in config.c

BOOL	CMD_RECONNECT (void)
{
	//char Version[256];
	//int i;
	//OpenStatus(topHWnd);
	ClosePort();
	//StatusText("Reconnecting USB...");
	if (OpenPort())
	{
		//StatusText("Resetting USB CopyNES...");
		ResetNES(RESET_COPYMODE);
		//StatusText("Retrieving internal version string...");  	  
		HWVer = FindVersion();
		//StatusOK();
		return TRUE;
	}
	else
	{
		//StatusOK();      
		HWVer = 0;
		return FALSE;
	}
}
