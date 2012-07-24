#include "StdAfx.h"
#define	CMD_NAME	"Make UNIF"

BOOL	CMD_MAKEUNIF (void)
{
	int i;
	char PRGback[MAX_PATH], CHRback[MAX_PATH], NESback[MAX_PATH];

	int battery, mirror = 0, fourscrn = 0, mcon = 0;
	char filepath[MAX_PATH], filename[MAX_PATH];

	PPlugin plugin = PromptPlugin(PLUG_STD);
	if (plugin == NULL)
		return FALSE;

	if (!PromptFile(topHWnd,"PRG data (*.PRG)\0*.prg\0\0",filepath,filename,NULL,"Select PRG segment","prg",FALSE))
		return FALSE;


	mirror = (MessageBox(topHWnd,"Vertical mirroring?",MSGBOX_TITLE,MB_YESNO | MB_ICONQUESTION) == IDYES);
	fourscrn = (MessageBox(topHWnd,"4-screen VRAM?",MSGBOX_TITLE,MB_YESNO | MB_ICONQUESTION) == IDYES);
	mcon = (MessageBox(topHWnd,"Mapper-controlled mirroring?",MSGBOX_TITLE,MB_YESNO | MB_ICONQUESTION) == IDYES);
	battery = (MessageBox(topHWnd,"Battery-backed RAM?",MSGBOX_TITLE,MB_YESNO | MB_ICONQUESTION) == IDYES);

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

  WriteUNIF(filename, plugin->name, battery, mirror, fourscrn, mcon);

	strcpy(Path_PRG,PRGback);
	strcpy(Path_CHR,CHRback);
	strcpy(Path_NES,NESback);

	return FALSE;
}
