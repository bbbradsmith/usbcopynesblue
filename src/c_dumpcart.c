#include "StdAfx.h"
#define	CMD_NAME	"Dump Cartridge"

BOOL	CMD_DUMPCART (void)
{
	int dtype = 2;
	int rbyte = 0, rcount = 0;
	PPlugin plugin;
	char *path, *ext;
	char filename[MAX_PATH];
	char fnamebuf[MAX_PATH];
	int cmode, battery, bytes, numk;
	BYTE ctype;
	WORD nblks;
	char Status[256];
	FILE *CRC, *DATA;

	// select board name
	plugin = PromptPlugin(PLUG_STD);
	if (plugin == NULL)
		return FALSE;

	PromptTitle = "Choose a ROM filename (omit extension)";
	if (!Prompt(topHWnd))
		return FALSE;
	strcpy(filename,PromptResult);

	OpenStatus(topHWnd);
	StatusText("Resetting USB CopyNES...");
	ResetNES(RESET_COPYMODE);

	StatusText("Unloading any existing plugin...");
	if (!LoadPlugin("clear.bin"))
	{
		CloseStatus();
		return FALSE;
	}
	RunCode();
	Sleep(SLEEP_SHORT);
  
	StatusText("Resetting USB CopyNES...");
	ResetNES(RESET_COPYMODE);
	StatusText("Loading plugin...");
	if (!LoadPlugin(plugin->file))
	{
		CloseStatus();
		return FALSE;
	}
	StatusText("Running plugin...");
	RunCode();
	Sleep(SLEEP_LONG);

	if (SaveCRC)
		CRC = fopen(strjoin3(fnamebuf,Path_CRC,filename,".txt"),"wb");
	
	cmode = 0;
	if (!ReadByte((BYTE *)&cmode))		// mirroring
	{
		CloseStatus();
		return FALSE;
	}
	battery = 0;
	while (1)
	{	// for the first 'header' byte, wait longer than usual
		// since the plugin might be busy doing size detection, which can take a while
		int s;
		if (!ReadByteEx((BYTE *)&nblks,TRUE) || !ReadByte((BYTE *)&nblks+1))
		{
			CloseStatus();
			return FALSE;
		}
		bytes = nblks << 8;
		numk = bytes / 1024;
		if (!ReadByte(&ctype))
		{
			CloseStatus();
			return FALSE;
		}
		if (ctype == 0)
			break;
		switch (ctype)
		{
		case 1:	ext = ".prg";
			path = Path_PRG;
			sprintf(Status,"Dumping %iK PRG ROM...",numk);	break;
		case 2:	ext = ".chr";
			path = Path_CHR;
			sprintf(Status,"Dumping %iK CHR ROM...",numk);	break;
		case 3:	ext = ".sav";
			path = Path_WRAM;
			sprintf(Status,"Dumping %iK WRAM...",numk);
			battery = 1;					break;
		case 4:	rbyte = nblks / 4;
			continue;
		default:StatusText("Unknown block type %i! Aborting...",ctype);
			StatusOK();
			return FALSE;					break;
		}
		StatusText(Status);
		DATA = fopen(strjoin3(fnamebuf,path,filename,ext),"w+b");
		if (DATA == NULL)
		{
			StatusText("Unable to open output file!");
			StatusOK();
			return FALSE;
		}
		for (s = 0; s < numk; s++)
		{
			int a;
			BYTE n;
			for (a = 0; a < 1024; a++)
			{
				if (!ReadByte(&n))
				{
					CloseStatus();
					return FALSE;
				}
				fwrite(&n,1,1,DATA);
			}
			if (rbyte)
			{
				rcount++;
				if (rbyte <= rcount)
				{
					rcount = 0;
					StatusText("Resetting USB CopyNES as requested by plugin...");
					ResetNES(RESET_COPYMODE);
					StatusText("Reloading plugin...");
					LoadPlugin(plugin->file);
					StatusText("Rerunning plugin...");
					RunCode();
					rbyte = 0;
					if (!ReadByte((BYTE *)&rbyte) || !ReadByte((BYTE *)&rbyte+1))
					{
						CloseStatus();
						return FALSE;
					}
					rbyte /= 4;
				}
			}
			StatusPercent((s*100)/numk);
		}
		StatusPercent(100);
		StatusText("...done!");
		if (SaveCRC)
			fprintf(CRC,"%s%s %08X\n",filename,ext,GetCRC(DATA));
		fclose(DATA);
	}

	if (SaveCRC)
		fclose(CRC);
	StatusText("Dump complete!");
	StatusOK();
	ResetNES(RESET_COPYMODE);
	{
		int scrn4 = (cmode & 0x2) >> 1;
		int mirror = (~cmode & 0x1);
		int mcon = (cmode & 0x4) >> 2;
		if (plugin->num == 999)
			return TRUE;
		WriteNES(filename,plugin->num,battery,mirror,scrn4);
		if (MakeUnif == 1)
		  WriteUNIF(filename,plugin->name,battery,mirror,scrn4,mcon);
		if (SaveFiles == 0)
		{
			unlink(strjoin3(fnamebuf,Path_CHR,filename,".chr"));
			unlink(strjoin3(fnamebuf,Path_PRG,filename,".prg"));
		}
	}
	return TRUE;
}
