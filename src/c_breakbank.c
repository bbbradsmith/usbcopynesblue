#include "StdAfx.h"
#define	CMD_NAME	"Break Banks"

BOOL	CMD_BREAKBANK (void)
{
	char filename[MAX_PATH], outfile[MAX_PATH];
	int banksize, numbanks, i, j;
	FILE *input, *output;

	if (!PromptFile(topHWnd,"Data files (*.PRG;*.CHR)\0*.prg;*.chr\0\0",filename,NULL,NULL,"Select a file to split...",NULL,FALSE))
		return FALSE;

	PromptTitle = "Enter bank size (in bytes)";
	if (!Prompt(topHWnd))
		return FALSE;
	while (!sscanf(PromptResult,"%i",&banksize))
	{
		MessageBox(topHWnd,"You must enter a number!",MSGBOX_TITLE,MB_OK | MB_ICONERROR);
		if (!Prompt(topHWnd))
			return FALSE;
	}
	OpenStatus(topHWnd);
	StatusText("Opening input file...");
	input = fopen(filename,"rb");
	if (input == NULL)
	{
		StatusText("Unable to open input file!");
		StatusOK();
		return FALSE;
	}
	StatusText("Determining file size......");
	fseek(input,0,SEEK_END);
	if (ftell(input) % banksize)
	{
		StatusText("Irregular file size!");
		StatusOK();
		return FALSE;
	}
	numbanks = ftell(input) / banksize;
	fseek(input,0,SEEK_SET);
	StatusText("Splitting...");
	for (i = 0; i < numbanks; i++)
	{
		char ext[5];
		ext[0] = '.';
		ext[1] = ((i / 0x100) % 16) + '0';	if (ext[1] > '9') ext[1] += 7;
		ext[2] = ((i / 0x10) % 16) + '0';	if (ext[2] > '9') ext[2] += 7;
		ext[3] = ((i / 0x1) % 16) + '0';	if (ext[3] > '9') ext[3] += 7;
		ext[4] = 0;
		strcpy(outfile,filename);
		strcat(outfile,ext);
		output = fopen(outfile,"wb");
		for (j = 0; j < banksize; j++)
		{
			BYTE n;
			fread(&n,1,1,input);
			fwrite(&n,1,1,output);
		}
		fclose(output);
		StatusPercent(i * 100 / numbanks);
	}
	StatusPercent(100);
	fclose(input);
	StatusText("Done splitting file!");
	StatusOK();
	return TRUE;
}
