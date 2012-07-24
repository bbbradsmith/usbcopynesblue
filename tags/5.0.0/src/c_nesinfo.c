#include "StdAfx.h"
#define	CMD_NAME	"NES Info"

BOOL	CMD_NESINFO (void)
{
	char Version[256];
	int i;
	OpenStatus(topHWnd);
	if (HWVer == 1)
	{
		StatusText("USB CopyNES did not return a version reply");
		StatusOK();
		return FALSE;
	}
	StatusText("Retrieving internal version string...");
	if (!WriteByteEx(0xA1,FALSE))
	{
		StatusText("Failed to request version string!");
		StatusOK();
		return FALSE;
	}

	for (i = 0; i < 256; i++)
	{
		if (!ReadByteEx(&Version[i],FALSE))
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
