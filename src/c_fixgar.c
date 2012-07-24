#include "StdAfx.h"
#define	CMD_NAME	"Fix Game Action Replay"

BOOL	UploadGAR (void)
{
	FILE *GAR;
	char filename[MAX_PATH];
	int j;
	char *filedata;
	
	if (!PromptFile(topHWnd,"Game Action Replay RAM file (gar.bin)\0gar.bin\0\0",filename,NULL,Path_PLUG,"Please select a valid Game Action Replay data file...","gar.bin",FALSE))
		return FALSE;
	
	if ((GAR = fopen(filename,"rb")) == NULL)
	{
		MessageBox(topHWnd,"Unable to open GAR data file!",MSGBOX_TITLE,MB_OK | MB_ICONERROR);
		return FALSE;
	}
	OpenStatus(topHWnd);
	StatusText("Resetting USB CopyNES...");
	ResetNES(RESET_COPYMODE);
	StatusText("Loading initialization plugin...");
	if (!LoadPlugin("garset.bin"))
	{
		fclose(GAR);
		CloseStatus();
		return FALSE;
	}
	StatusText("Running initialization plugin...");
	RunCode();
	Sleep(SLEEP_LONG);
	StatusText("Loading upload plugin...");
	if (!LoadPlugin("garup.bin"))
	{
		fclose(GAR);
		CloseStatus();
		return FALSE;
	}
	StatusText("Running upload plugin...");
	RunCode();
	StatusText("Uploading from data file...");

	filedata = malloc(1024);
	for (j = 0; j < 2; j++)
	{
    fread(filedata, 1024, 1, GAR);
    if (!WriteBlock(filedata, 1024))
		{
			CloseStatus();
			fclose(GAR);
			free(filedata);
			return FALSE;
		}
		StatusPercent((j * 100) / 2);
	}

	StatusPercent(100);
	StatusText("...done!");
	fclose(GAR);
	free(filedata);
	StatusOK();
	ResetNES(RESET_COPYMODE);
	return TRUE;
}

BOOL	DownloadGAR (void)
{
	FILE *GAR;
	char filename[MAX_PATH];
	int i;

	if (!PromptFile(topHWnd,"Game Action Replay RAM file (gar_d.bin)\0gar_d.bin\0\0",filename,NULL,Path_PLUG,"Please specify where to save Game Action Replay RAM data...","gar_d.bin",TRUE))
		return FALSE;

	if ((GAR = fopen(filename,"wb")) == NULL)
	{
		MessageBox(topHWnd,"Unable to open file for output!",MSGBOX_TITLE,MB_OK | MB_ICONERROR);
		return FALSE;
	}
	OpenStatus(topHWnd);
	StatusText("Resetting USB CopyNES...");
	ResetNES(RESET_COPYMODE);
	StatusText("Loading initialization plugin...");
	if (!LoadPlugin("garset.bin"))
	{
		fclose(GAR);
		CloseStatus();
		return FALSE;
	}
	StatusText("Running initialization plugin...");
	RunCode();
	Sleep(SLEEP_LONG);
	StatusText("Loading download plugin...");
	if (!LoadPlugin("gardn.bin"))
	{
		fclose(GAR);
		CloseStatus();
		return FALSE;
	}
	StatusText("Running download plugin...");
	RunCode();
	StatusText("Saving to file...");
	for (i = 0; i < 0x800; i++)
	{
		BYTE n;
		if (!ReadByte(&n))
		{
			fclose(GAR);
			CloseStatus();
			return FALSE;
		}
		fwrite(&n,1,1,GAR);
		if (!(i & 0x7))
			StatusPercent((i*100)/2048);
	}
	fclose(GAR);
	StatusText("Download complete!");
	StatusOK();
	ResetNES(RESET_COPYMODE);
	return TRUE;
}

BOOL	CMD_FIXGAR (void)
{
	int CMD = MessageBox(topHWnd,"What do you wish to do?\nYES => Upload code to broken GAR\nNO => Download code from working GAR",MSGBOX_TITLE,MB_YESNOCANCEL | MB_ICONQUESTION);
	if (CMD == IDYES)
		return UploadGAR();
	else if (CMD == IDNO)
		return DownloadGAR();
	else	return FALSE;
}
