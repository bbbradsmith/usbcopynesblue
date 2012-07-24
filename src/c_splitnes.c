#include "StdAfx.h"
#define	CMD_NAME	"Split .NES"

BOOL	SplitIt (char *infile, char *filename)
{
	FILE *NES, *PRG, *CHR;
	char outprg[MAX_PATH], outchr[MAX_PATH];
	BYTE buf[1024];
	int PRGcount, CHRcount;
	BOOL isError = FALSE;
	int i;
	
	NES = fopen(infile,"rb");
	PRG = fopen(strjoin3(outprg,Path_PRG,filename,".prg"),"wb");
	CHR = fopen(strjoin3(outchr,Path_CHR,filename,".chr"),"wb");
	if (NES == NULL)
	{
		MessageBox(topHWnd,"Unable to open input file!",MSGBOX_TITLE,MB_OK | MB_ICONERROR);
		isError = TRUE;
	}
	else if (PRG == NULL)
	{
		MessageBox(topHWnd,"Unable to open PRG output file!",MSGBOX_TITLE,MB_OK | MB_ICONERROR);
		isError = TRUE;
	}
	else if (CHR == NULL)
	{
		MessageBox(topHWnd,"Unable to open CHR output file!",MSGBOX_TITLE,MB_OK | MB_ICONERROR);
		isError = TRUE;
	}
	if (isError)
	{
		if (NES != NULL)
			fclose(NES);
		if (PRG != NULL)
			fclose(PRG);
		if (CHR != NULL)
			fclose(CHR);
		return FALSE;
	}
	fread(buf,1,16,NES);
	if (strncmp(buf,"NES\x1A",4))
	{
		MessageBox(topHWnd,"File is not a valid iNES ROM image!",MSGBOX_TITLE,MB_OK | MB_ICONERROR);
		fclose(NES);
		fclose(PRG);
		fclose(CHR);
		return FALSE;
	}
	PRGcount = buf[0x4];
	CHRcount = buf[0x5];
	fseek(NES,0,SEEK_END);
	if ((PRGcount * 16384 + CHRcount * 8192 + 16) < ftell(NES))
	{
		MessageBox(topHWnd,"File too small!",MSGBOX_TITLE,MB_OK | MB_ICONERROR);
		fclose(NES);
		fclose(PRG);
		fclose(CHR);
		return FALSE;
	}
	if ((PRGcount * 16384 + CHRcount * 8192 + 16) > ftell(NES))
		MessageBox(topHWnd,"Warning! file too large, splitting anyways...",MSGBOX_TITLE,MB_OK | MB_ICONWARNING);
	fseek(NES,16,SEEK_SET);
	for (i = 0; i < PRGcount * 16; i++)
	{
		fread(buf,1,1024,NES);
		fwrite(buf,1,1024,PRG);
	}
	for (i = 0; i < CHRcount * 8; i++)
	{
		fread(buf,1,1024,NES);
		fwrite(buf,1,1024,CHR);
	}
	fclose(NES);
	fclose(PRG);
	fclose(CHR);
	MessageBox(topHWnd,"Done splitting!",MSGBOX_TITLE,MB_OK);
	return TRUE;
}

BOOL	CMD_SPLITNES (void)
{
	char filepath[MAX_PATH], filename[MAX_PATH];
	int i;
	PromptFile(topHWnd,"NES Files (*.NES)\0*.nes\0\0",filepath,filename,NULL,"Select a ROM","nes",FALSE);
	if (!filepath[0])
		return FALSE;
	i = strlen(filename);
	while (filename[i] != '.')
		i--;
	filename[i] = 0;	// drop the extension
	return SplitIt(filepath,filename);
}
