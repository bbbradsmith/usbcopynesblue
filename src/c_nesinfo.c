#include "StdAfx.h"
#define	CMD_NAME	"NES Info"

BOOL	CMD_NESINFO (void)
{
	char Version[256];
	int i;
	OpenStatus(topHWnd);
	InitPort();
	if (HWVer == 1)
	{
		if (ParPort == -1)
		{
			StatusText("CopyNES did not return a version reply!");
			StatusOK();
			return FALSE;
		}
		else
		{
			StatusText("CopyNES did not return a version reply, assuming version 1");
			StatusOK();
			return TRUE;
		}
	}
	StatusText("Retrieving internal version string...");
	if (!WriteByteEx(0xA1,3,FALSE))
	{
		StatusText("Failed to request version string!");
		StatusOK();
		return FALSE;
	}

	for (i = 0; i < 256; i++)
	{
		if (!ReadByteEx(&Version[i],1,FALSE))
		{
			StatusText("Error reading version string!");
			StatusOK();
			return FALSE;
		}
		if (!Version[i])
			break;
	}
	StatusText(Version);
	StatusOK();
	return TRUE;
}
