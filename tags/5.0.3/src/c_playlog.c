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
	unsigned int loop_start=0;
	unsigned int dpcm=0;
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
			dpcm = 0;
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
		else if (!strncmp(line, "LOOPSTART",9)) //Loop Start Point
		{
			loop_start = ftell(f);
		}
		else if (!strncmp(line, "LOOPEND",7)) //Loop End Point
		{
			if(loop_start)
				fseek(f,loop_start,SEEK_SET);
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
				if((adr == 0x4010) && (val & 0xCF))
					dpcm |= 1;
				if((adr == 0x4011) && (val & 0x7F))
					dpcm |= 2;
				if((adr == 0x4012) && (val & 0xFF))
					dpcm |= 4;
				if((adr == 0x4013) && (val & 0xFF))
					dpcm |= 8;
				if((adr == 0x4015) && (val & 0x10))
					dpcm |= 0x10;

				if((dpcm > 0x10) && (dpcm < 0x20))
				{
					StatusText("Warning: This track uses DPCM");
					dpcm |= 0x20;
				}


				//It is true that VRC7 requires delay. however, the delay is more than achieved
				//by the amount of time it takes for the copynes to receive the next 3 bytes.
				//a single jsr read_byte, takes at least 52 cycles to complete.  The delay loop
				//required is at least 42 cycles, and the one used by lagrangepoint takes 61 cyles.
				//The total effective time for the next address/value pair to be written is at least
				//168 cycles.
				//if(adr == 0x9030)
				//{
				//	WriteByte(0x02);
				//}
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
