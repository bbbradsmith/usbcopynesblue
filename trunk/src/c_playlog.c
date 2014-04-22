#include "StdAfx.h"
#define	CMD_NAME	"Play NSF LOG"

#define MAX_LOG_LEN     1024 * 1024 * 10

unsigned int get_percent(FILE *f, unsigned int start)
{
	unsigned int log_pos, log_end;
	log_pos = ftell(f);
	fseek(f,0,SEEK_END);
	log_end = ftell(f);
	fseek(f,log_pos,SEEK_SET);
	if((log_end-start)==0)
		return 0;
	return ((log_pos - start)*100) / (log_end-start);
}

BOOL    LogPlay (char *filename)
{
	char line[256];
	unsigned char * log;
	unsigned int log_pos;
	unsigned int reset=0;
	FILE *f;

	OpenStatus(topHWnd);

	log_pos = 0;

	f = fopen(filename,"rt");
	if (f == NULL)
	{
		StatusText("Could not open file.");
		StatusOK();
		free(log);
		return FALSE;
	}

	StatusPercent(0);
	StatusButtonAsync(TRUE);
	do
	{
		fgets(line,sizeof(line),f);
		if(feof(f))
		{
			log_pos = ftell(f);
			StatusPercent(get_percent(f,log_pos));
			if(reset)
				WriteByte(0x01);
			DoEvents();
			if(StatusButtonPressed())
				break;
			else
				continue;
		}

		if(!strncmp(line, "BEGIN", 5))
		{
			StatusText("Resetting USB CopyNES...");
			ResetNES(RESET_COPYMODE);
			StatusText("Loading plugin...");
			if (!LoadPlugin("playlog.bin"))
			{
				StatusText("Could not load playlog.bin.");
				StatusOK();
				return FALSE;
			}
			StatusText("Initializing plugin...");
			RunCode();
			Sleep(SLEEP_SHORT);
			StatusText("Playing...");
			StatusText(line+5);
			reset=1;
			log_pos = ftell(f);
		}
		else if (!strncmp(line, "END", 3))
		{
			StatusPercent(100);
			break;
		}
		else if (!strncmp(line, "PLAY", 4)) // advance frame
		{
			StatusPercent(get_percent(f,log_pos));
			if(reset)
				WriteByte(0x01);
			DoEvents();
			if(StatusButtonPressed())
				break;
		}
		else if (!strncmp(line, "WRITE", 5))
		{
			unsigned int adr, val;
			sscanf(line,"WRITE(%04X,%02X)",&adr,&val);
			if(reset)
			{
				WriteByte((adr>>8)&0xFF);
				WriteByte(adr&0xFF);
				WriteByte(val);

				if (adr == 0x9030) // VRC7 requires delay
				{
					WriteByte(0x02);
				}
			}
		}

	} while (1);
	fclose(f);
	StatusText("Done.");
	CloseStatus();
	ResetNES(RESET_COPYMODE);
	return TRUE;
}

BOOL    CMD_PLAYLOG (void)
{
	char filename[MAX_PATH];
	if (!PromptFile(topHWnd,"Register dumps (*.TXT;*.LOG)\0*.txt;*.log;*.*\0\0",filename,NULL,NULL,"Select a file...",NULL,FALSE))
		return FALSE;

	return LogPlay(filename);
}
