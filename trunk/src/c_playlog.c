#include "StdAfx.h"
#define	CMD_NAME	"Play NSF LOG"

#define MAX_LOG_LEN     1024 * 1024 * 10

BOOL    LogPlay (char *filename)
{
	char line[256];
	unsigned char * log;
	unsigned int log_len;
	unsigned int log_pos;
	FILE *f;

	OpenStatus(topHWnd);

	log_len = 0;
	log = malloc(MAX_LOG_LEN);
	if (log == NULL)
	{
		StatusText("Could not allocate memory for log data.");
		StatusOK();
		return FALSE;
	}

	StatusText("Parsing log file...");
	f = fopen(filename,"rt");
	if (f == NULL)
	{
		StatusText("Could not open file.");
		StatusOK();
		free(log);
		return FALSE;
	}
	do
	{
		fgets(line,sizeof(line),f);

		if (!strncmp(line, "PLAY", 4)) // advance frame
		{
			log[log_len] = 0x01; // next frame command
			++log_len;
		}
		else if (!strncmp(line, "WRITE", 5))
		{
			unsigned int adr, val;
			sscanf(line,"WRITE(%04X,%02X)",&adr,&val);
			log[log_len+0] = (adr >> 8) & 0xFF;
			log[log_len+1] = adr & 0xFF;
			log[log_len+2] = val;
			log_len += 3;

			if (adr == 0x9030) // VRC7 requires delay
			{
				log[log_len] = 0x02; // delay command
				++log_len;
			}
		}

		if ((log_len + 4) >= MAX_LOG_LEN)
		{
			StatusText("Log exceeds maximum size!");
			StatusOK();
			free(log);
			return FALSE;
		}
	} while (!feof(f));
	fclose(f);

	StatusText("Resetting USB CopyNES...");
	ResetNES(RESET_COPYMODE);
	StatusText("Loading plugin...");
	if (!LoadPlugin("playlog.bin"))
	{
		StatusText("Could not load playlog.bin.");
		StatusOK();
		free(log);
		return FALSE;
	}
	StatusText("Initializing plugin...");
	RunCode();
	Sleep(SLEEP_SHORT);
	StatusText("Playing...");
	StatusPercent(0);

	for (log_pos=0; log_pos<log_len;)
	{
		int block_size = 256;
		int left =  log_len-log_pos;
		if (left < block_size)
			block_size = left;

		if (!WriteBlock(log + log_pos,block_size))
		{
			StatusText("Error sending block.");
			StatusOK();
			free(log);
			return FALSE;
		}
		log_pos += block_size;
		StatusPercent(log_pos * 100 / log_len);
	}
	StatusText("Done.");
	StatusOK();
	free(log);
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
