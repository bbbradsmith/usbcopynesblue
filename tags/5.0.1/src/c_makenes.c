#include "StdAfx.h"
#define	CMD_NAME	"Make .NES"

BOOL	CMD_MAKENES (void)
{
	int i;
	char PRGback[MAX_PATH], CHRback[MAX_PATH], NESback[MAX_PATH];

	int mapper, battery, mirror, fourscrn;
	char filepath[MAX_PATH], filename[MAX_PATH];
	if (!PromptFile(topHWnd,"PRG data (*.PRG)\0*.prg\0\0",filepath,filename,NULL,"Select PRG segment","prg",FALSE))
		return FALSE;

	PromptTitle = "Enter mapper number:";
	if (!Prompt(topHWnd))
		return FALSE;
	mapper = atoi(PromptResult);

	battery = (MessageBox(topHWnd,"Battery-backed RAM?",MSGBOX_TITLE,MB_YESNO | MB_ICONQUESTION) == IDYES);
	mirror = (MessageBox(topHWnd,"Vertical mirroring?",MSGBOX_TITLE,MB_YESNO | MB_ICONQUESTION) == IDYES);
	fourscrn = (MessageBox(topHWnd,"4-screen VRAM?",MSGBOX_TITLE,MB_YESNO | MB_ICONQUESTION) == IDYES);

	strcpy(PRGback,Path_PRG);
	strcpy(CHRback,Path_CHR);
	strcpy(NESback,Path_NES);

	i = strlen(filepath);
	while (i > 0)
		if (filepath[--i] == '\\')
		{
			filepath[++i] = 0;
			break;
		}

	i = strlen(filename);
	while (i > 0 && filename[i] != '.')
		i--;
	if (i)	filename[i] = 0;

	strcpy(Path_PRG,filepath);
	strcpy(Path_CHR,filepath);
	strcpy(Path_NES,filepath);

	WriteNES(filename, mapper, battery, mirror, fourscrn);

	strcpy(Path_PRG,PRGback);
	strcpy(Path_CHR,CHRback);
	strcpy(Path_NES,NESback);

	return FALSE;
}