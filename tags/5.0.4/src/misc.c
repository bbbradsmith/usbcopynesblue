#include "StdAfx.h"
#include <time.h>

char	*strjoin3 (char *out, const char *in1, const char *in2, const char *in3)
{
	strcpy(out,in1);
	strcat(out,in2);
	strcat(out,in3);
	return out;
}

void	UNIFchunk (FILE *file, char *name, void *data, int len)
{
	fwrite(name,4,1,file);
	fwrite(&len,4,1,file);
	if (data != NULL)	fwrite(data,len,1,file);
}
void	WriteUNIF (char *basename, char *board, int battery, int mirror, int fourscrn, int mcon)
{
	FILE *UNIF, *PRG, *CHR;
	int a, b;
	char filename[MAX_PATH];
	if (battery)	// 'battery' merely indicates the possibility - need to confirm
		battery = (MessageBox(topHWnd,"Really has battery?","UNIF",MB_YESNO | MB_ICONQUESTION) == IDYES);
	UNIF = fopen(strjoin3(filename,Path_NES,basename,".unf"),"wb");
	PRG = fopen(strjoin3(filename,Path_PRG,basename,".prg"),"rb");
	if (!PRG)
	{
		fclose(UNIF);
		return;
	}
	CHR = fopen(strjoin3(filename,Path_CHR,basename,".chr"),"rb");
	fwrite("UNIF",4,1,UNIF);
	a = 7;
	fwrite(&a,4,1,UNIF);
	a = 0;
	for (b = 0; b < 6; b++)
		fwrite(&a,4,1,UNIF);

	UNIFchunk(UNIF,"MAPR",board,strlen(board)+1);
	{
		char dumpinfo[204];
		time_t curtime = time(&curtime);
		struct tm *mytime = localtime(&curtime);
		int year;
		memset(dumpinfo,0,204);

		PromptTitle = "Enter your name for Dumper Information block (cancel for default)";
		if (Prompt(topHWnd))
			strcpy(&dumpinfo[0],PromptResult);
		else	strcpy(&dumpinfo[0],"TheMadDumper");
		dumpinfo[99] = 0;	// null terminate
		dumpinfo[100] = mytime->tm_mday;
		dumpinfo[101] = mytime->tm_mon + 1;
		year = mytime->tm_year + 1900;
		dumpinfo[102] = (year & 0x00FF);
		dumpinfo[103] = (year & 0xFF00) >> 8;
		sprintf(&dumpinfo[104],"%sCopyNES Blue v5.0.4", (ParPort == -1) ? "USB " : "");
		UNIFchunk(UNIF,"DINF",dumpinfo,204);
	}

	PromptTitle = "Cartridge Name (cancel for none)";
	if (Prompt(topHWnd))
		UNIFchunk(UNIF,"NAME",PromptResult,strlen(PromptResult) + 1);
	
	PromptTitle = "0:joypad, 1:zapper, 2:ROB, 3:Arkanoid, 4:PowerPad, 5:FourScore\n\nEnter controllers used, separated w/spaces (e.g. 0 1 5)\n";
	if (Prompt(topHWnd))
	{
		unsigned int i, n, ctype;
		n = strlen(PromptResult);
		PromptResult[n+1] = 0;
		PromptResult[n+1] = ' ';
		for (i = 0; i < strlen(PromptResult); i++)
		{
			if (PromptResult[i] == ' ')
			{
				ctype |= 1 << n;
				n = 0;
			}
			else	n = (n * 10) + (PromptResult[i] - '0');
		}
		UNIFchunk(UNIF,"CTRL",&ctype,4);
	}
	{
		PromptTitle = "Description Text (cancel for none)";
		if (PromptLong(topHWnd))
			UNIFchunk(UNIF,"READ",PromptResult,strlen(PromptResult) + 1);
	}
	{
		unsigned char mirr = 0;
		if (mirror)	mirr = 1;
		if (fourscrn)	mirr = 4;
		if (mcon)	mirr = 5;
		UNIFchunk(UNIF,"MIRR",&mirr,1);
	}
	if (battery)	UNIFchunk(UNIF,"BATR",&battery,1);
	if (ROMstring[0])
	{
		char rtype;
		int rsize = 0, rnum = 0;
		int numstrings = strlen(ROMstring) / 6;
		int i;
		FILE *SEG;

		for (i = 0; i < numstrings; i++)
		{
			int n, x;
			FILE *FROM;
			unsigned long SegCRC;
			char CDstr[5], CKstr[5];

			rtype = ROMstring[i*6+0];
			rnum = ROMstring[i*6+1]-'0';
			rsize = 0;
			for (n = 2; n < 6; n++)
			{
				x = toupper(ROMstring[i*6+n]);
				x -= '0';
				if (x > 9)
					x -= 17;
				rsize |= x;
				rsize <<= 4;
			}
			rsize <<= 4;
			if (rtype == 'P')
			{
				sprintf(CDstr,"PRG%X",rnum);
				sprintf(CKstr,"PCK%X",rnum);
				FROM = PRG;
				sprintf(filename,"%s%s.pr%X",Path_PRG,basename,rnum);
			}
			else if (rtype == 'C')
			{
				sprintf(CDstr,"CHR%X",rnum);
				sprintf(CKstr,"CCK%X",rnum);
				FROM = CHR;
				sprintf(filename,"%s%s.ch%X",Path_CHR,basename,rnum);
			}
			SEG = fopen(filename,"w+b");
			UNIFchunk(UNIF,CDstr,NULL,rsize);
			for (n = 0; n < rsize; n++)
			{
				BYTE x;
				fread(&x,1,1,FROM);
				fwrite(&x,1,1,UNIF);
				fwrite(&x,1,1,SEG);
			}
			SegCRC = GetCRC(SEG);
			UNIFchunk(UNIF,CKstr,&SegCRC,4);
			fclose(SEG);
			if (!SaveFiles)
				unlink(filename);	// delete the PRG/CHR segment
		}
	}
	else
	{
		int i;
		int PRGlen, CHRlen;
		unsigned long PRGcrc, CHRcrc;

		PRGcrc = GetCRC(PRG);
		UNIFchunk(UNIF,"PCK0",&PRGcrc,4);

		if (CHR)
		{
			CHRcrc = GetCRC(CHR);
			UNIFchunk(UNIF,"CCK0",&CHRcrc,4);
		}

		fseek(PRG,0,SEEK_END);
		PRGlen = ftell(PRG);
		fseek(PRG,0,SEEK_SET);
		UNIFchunk(UNIF,"PRG0",NULL,PRGlen);		// don't write any data, doing that below
		for (i = 0; i < PRGlen; i++)
		{
			BYTE a;
			fread(&a,1,1,PRG);
			fwrite(&a,1,1,UNIF);
		}

		if (CHR)
		{
			fseek(CHR,0,SEEK_END);
			CHRlen = ftell(CHR);
			fseek(CHR,0,SEEK_SET);
			UNIFchunk(UNIF,"CHR0",NULL,CHRlen);	// don't write any data, doing that below
			for (i = 0; i < CHRlen; i++)
			{
				BYTE a;
				fread(&a,1,1,CHR);
				fwrite(&a,1,1,UNIF);
			}
		}
	}
	fclose(UNIF);
	fclose(PRG);
	if (CHR)
		fclose(CHR);
	MessageBox(topHWnd,".UNIF created successfully!","CopyNES Blue",MB_OK);
}
void	WriteNES (char *basename, int mapper, int battery, int mirror, int fourscrn, int nes2, int wram, int vram, int submapper, int tv)
{
	FILE *NES, *PRG, *CHR;
	char filename[MAX_PATH];
	int a;
	unsigned char prglen = 0, chrlen = 0, prgchr_hi = 0, maplo, maphi, mapext, temp;
	if (mapper == -1)
		return;		// UNIF only, do not generate .NES

	if (battery)	// 'battery' merely indicates the possibility - need to confirm
		battery = (MessageBox(topHWnd,"Really has battery?","NES",MB_YESNO | MB_ICONQUESTION) == IDYES);
	
	NES = fopen(strjoin3(filename,Path_NES,basename,".nes"),"wb");
	if(!NES)
	{
		MessageBox(topHWnd,"Failed to create .NES File","USB CopyNES",MB_OK);
		return;
	}
	PRG = fopen(strjoin3(filename,Path_PRG,basename,".prg"),"rb");
	if(!PRG)
	{
		MessageBox(topHWnd,"Failed to create .NES File","USB CopyNES",MB_OK);
		fclose(NES);
		unlink(strjoin3(filename,Path_NES,basename,".nes"));
		return;
	}
	CHR = fopen(strjoin3(filename,Path_CHR,basename,".chr"),"rb");

	fwrite("NES\x1A",4,1,NES);
	fseek(PRG,0,SEEK_END);
	prglen = (unsigned char)((ftell(PRG) / 16384) & 0xFF);
	if(nes2) prgchr_hi = (unsigned char)(((ftell(PRG) / 16384) & 0xF00) >> 8);
	fwrite(&prglen,1,1,NES);
	fseek(PRG,0,SEEK_SET);
	if (CHR)
	{
		fseek(CHR,0,SEEK_END);
		chrlen = (unsigned char)((ftell(CHR) / 8192) & 0xFF);
		prgchr_hi |= (unsigned char)(((ftell(CHR) / 8192) & 0xF00) >> 4);
		fseek(CHR,0,SEEK_SET);
	}
	fwrite(&chrlen,1,1,NES);
	maplo = ((mapper & 0x0F) << 4) | (mirror) | (battery << 1) | (fourscrn << 3);
	fwrite(&maplo,1,1,NES);
	maphi = (mapper & 0xF0);
	if(nes2) maphi |= 0x08;
	fwrite(&maphi,1,1,NES);
	if(!nes2) fwrite("\0\0\0\0\0\0\0\0",1,8,NES);
	else
	{
		mapext = ((mapper & 0xF00) >> 8);
		mapext |= ((submapper & 0x0F) << 4);
		fwrite(&mapext,1,1,NES);
		fwrite(&prgchr_hi,1,1,NES);
		temp = wram & 0xFF;
		fwrite(&temp,1,1,NES);
		temp = vram & 0xFF;
		fwrite(&temp,1,1,NES);
		temp = tv & 0x03;
		fwrite(&temp,1,1,NES);
		fwrite("\0\0\0",1,3,NES);
	}
	for (a = 0; a < prglen; a++)
	{
		char PRGdata[16384];
		fread(PRGdata,16384,1,PRG);
		fwrite(PRGdata,16384,1,NES);
	}
	for (a = 0; a < chrlen; a++)
	{
		char CHRdata[8192];
		fread(CHRdata,8192,1,CHR);
		fwrite(CHRdata,8192,1,NES);
	}
	fclose(PRG);
	if (CHR)
		fclose(CHR);
	fclose(NES);

	MessageBox(topHWnd,".NES created successfully!","CopyNES Blue",MB_OK);
}

