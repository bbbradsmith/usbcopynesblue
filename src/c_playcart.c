#include "StdAfx.h"
#define	CMD_NAME	"Play Cartridge"

BOOL	CMD_PLAYCART (void)
{
	InitPort();
	ResetNES(RESET_PLAYMODE);
	MessageBox(topHWnd,"Playing game - press OK to terminate",MSGBOX_TITLE,MB_OK);
	ResetNES(RESET_COPYMODE);
	return TRUE;
}