#include "StdAfx.h"
#define	CMD_NAME	"Make .NES"

BOOL	CMD_MAKENES (void)
{
	int i;
	char PRGback[MAX_PATH], CHRback[MAX_PATH], NESback[MAX_PATH];

	int mapper, battery, mirror, fourscrn, nes2, wram=0, vram=0, submapper=0, tv=0;
	char filepath[MAX_PATH], filename[MAX_PATH];
	if (!PromptFile(topHWnd,"PRG data (*.PRG)\0*.prg\0\0",filepath,filename,NULL,"Select PRG segment","prg",FALSE))
		return FALSE;

	nes2 = (MessageBox(topHWnd,"Use NES2.0 format?",MSGBOX_TITLE,MB_YESNO | MB_ICONQUESTION) == IDYES);

	PromptTitle = "Enter mapper number:";
	if (!Prompt(topHWnd))
		return FALSE;
	mapper = atoi(PromptResult) & 0xFFF;
	if(!nes2) mapper &= 0xFF;	//iNES only supports up to 256 mappers.
	if(nes2) {
		PromptTitle = "Enter submapper number:";
		if(Prompt(topHWnd))
			submapper = atoi(PromptResult) & 0x0F;
	}

	battery = (MessageBox(topHWnd,"Battery-backed RAM?",MSGBOX_TITLE,MB_YESNO | MB_ICONQUESTION) == IDYES);
	mirror = (MessageBox(topHWnd,"Vertical mirroring?",MSGBOX_TITLE,MB_YESNO | MB_ICONQUESTION) == IDYES);
	fourscrn = (MessageBox(topHWnd,"4-screen VRAM?",MSGBOX_TITLE,MB_YESNO | MB_ICONQUESTION) == IDYES);

	if(nes2) {
		if(battery) {
			PromptTitle = "Enter Battery wram size: " \
							"0 = 0, 1 = 128, 2 = 256, 3 = 512, " \
							"4 = 1K, 5 = 2K, 6 = 4K, 7 = 8K, " \
							"8 = 16K, 9 = 32K, 10 = 64K, 11 = 128K, " \
							"12 = 256K, 13 = 512K, 14 = 1M";
			if(Prompt(topHWnd))
				wram = (atoi(PromptResult) & 0x0F) << 4;
		}
		PromptTitle = "Enter wram size: " \
							"0 = 0, 1 = 128, 2 = 256, 3 = 512, " \
							"4 = 1K, 5 = 2K, 6 = 4K, 7 = 8K, " \
							"8 = 16K, 9 = 32K, 10 = 64K, 11 = 128K, " \
							"12 = 256K, 13 = 512K, 14 = 1M";
		if(Prompt(topHWnd))
			wram |= (atoi(PromptResult) & 0x0F);
		if (battery) {
			PromptTitle = "Enter Battery chr ram size: " \
							"0 = 0, 1 = 128, 2 = 256, 3 = 512, " \
							"4 = 1K, 5 = 2K, 6 = 4K, 7 = 8K, " \
							"8 = 16K, 9 = 32K, 10 = 64K, 11 = 128K, " \
							"12 = 256K, 13 = 512K, 14 = 1M";
			if(Prompt(topHWnd))
				vram = (atoi(PromptResult) & 0x0F) << 4;
		}
		
		PromptTitle = "Enter chr ram size: " \
							"0 = 0, 1 = 128, 2 = 256, 3 = 512, " \
							"4 = 1K, 5 = 2K, 6 = 4K, 7 = 8K, " \
							"8 = 16K, 9 = 32K, 10 = 64K, 11 = 128K, " \
							"12 = 256K, 13 = 512K, 14 = 1M";
		if(Prompt(topHWnd))
			vram |= (atoi(PromptResult) & 0x0F);

		PromptTitle = "TV System - 0=NTSC, 1=PAL, 2=Both";
		if(Prompt(topHWnd))
			tv = atoi(PromptResult) & 0x03;
	}

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

	WriteNES(filename, mapper, battery, mirror, fourscrn, nes2,wram,vram,submapper,tv);

	strcpy(Path_PRG,PRGback);
	strcpy(Path_CHR,CHRback);
	strcpy(Path_NES,NESback);

	return TRUE;
}