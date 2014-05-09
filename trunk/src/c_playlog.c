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
	unsigned int log_pos;
	unsigned int loop_start=0;
	unsigned int dpcm=0;
	unsigned int n163=0;
	unsigned int reset=0;
	unsigned int adr,val;
	unsigned int vrc7adr=0xC0;
	int i;
	FILE *f;

	OpenStatus(topHWnd);

	log_pos = 0;

	f = fopen(filename,"rt");
	if (f == NULL)
	{
		StatusText("Could not open file.");
		StatusOK();
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
			if(!reset)
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
				reset=1;
			}
			StatusText("Playing...");
			StatusText(line+5);
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
		else if (!strncmp(line, "INIT", 4)) //Init the APU to default state
		{
			for(i=0;i<0x15;i++)
			{
				WriteByte(0x40);WriteByte(i&0xFF);WriteByte(0x00);
			}
			WriteByte(0x40);WriteByte(i&0xFF);WriteByte(0x0F);
			WriteByte(0x01);	//Wait delay a frame.
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
		else if (!strncmp(line, "DWRITE",6)) //Direct Write. 
		{
			sscanf(line,"WRITE(%04X,%02X)",&adr,&val);
			if(reset)
			{
				WriteByte(0x02);
				WriteByte((adr>>8)&0xFF);
				WriteByte(adr&0xFF);
				WriteByte(val);
			}
		}
		else if (!strncmp(line, "WRITE", 5))
		{
			sscanf(line,"WRITE(%04X,%02X)",&adr,&val);
			if(reset)
			{
				if(adr == 0x9010)
				{
					vrc7adr = val & 0x3F;
					vrc7adr |= 0xC0;
				}
				else if (adr == 0x9030)
				{
					WriteByte(vrc7adr);
					WriteByte(val);
				}
				else if ((adr >= 0x4000) && (adr <= 0x4017))
				{
					adr&=0x1F;
					adr+=0xA8;
					WriteByte(adr);
					WriteByte(val);
				}
				else if ((adr >= 0xB000) && (adr <= 0xB002))
				{
					adr&=0x03;
					adr+=0xA5;
					WriteByte(adr);
					WriteByte(val);
				}
				else if ((adr >= 0xA000) && (adr <= 0xA002))
				{
					adr&=0x03;
					adr+=0xA2;
					WriteByte(adr);
					WriteByte(val);
				}
				else if ((adr >= 0x9000) && (adr <= 0x9003))
				{
					adr&=0x03;
					adr+=0x9E;
					WriteByte(adr);
					WriteByte(val);
				}
				else if ((adr & 0xF800) == 0xF800)
				{
					WriteByte(0x9D);
					WriteByte(val);
				}
				else if((adr & 0xF800) == 0x4800)
				{
					WriteByte(0x9C);
					WriteByte(val);
				}	
				else
				{
					WriteByte((adr>>8)&0xFF);
					WriteByte(adr&0xFF);
					WriteByte(val);
				}
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
	if (!PromptFile(topHWnd,"Register dumps (*.TXT;*.LOG)\0*.txt;*.log\0All Files (*.*)\0*.*\0\0",filename,NULL,NULL,"Select a file...",NULL,FALSE))
		return FALSE;

	return LogPlay(filename);
}
