#include "StdAfx.h"
#define	CMD_NAME	"Play Register Dump"

BOOL	RegPlayNES (char *filename)
{
	int FrameNum = 0, NumFrames = 0;
	FILE *REGDATA;
	OpenStatus(topHWnd);
	StatusText("Resetting USB CopyNES...");
	ResetNES(RESET_COPYMODE);
	StatusText("Loading plugin...");
	if (!LoadPlugin("rdump1.bin"))
	{
		CloseStatus();
		return FALSE;
	}
	StatusText("Initializing plugin...");
	RunCode();
	Sleep(SLEEP_SHORT);
	REGDATA = fopen(filename,"rt");
	StatusText("Playing...");
	StatusPercent(0);
	while (!feof(REGDATA))
	{
		char data[32];
		fscanf(REGDATA,"%[^\n]\n",data);
		if (!strncmp(data,"Frame",5))
			NumFrames++;
	}
	rewind(REGDATA);
	while (!feof(REGDATA))
	{
		char data[32];
		fscanf(REGDATA,"%[^\n]\n",data);
		if (!strncmp(data,"Write",5))
		{
			int Addr, Val;
			sscanf(data,"Write:  %04X:%02X\n",&Addr,&Val);
			if (!WriteByte((BYTE)(0x80 | ((Val & 0x80) >> 1) | (Addr & 0x1F))) || !WriteByte((BYTE)(Val & 0x7F)))
			{
				CloseStatus();
				return FALSE;
			}
		}
		if (!strncmp(data,"Frame",5))
		{
			FrameNum++;
			StatusPercent((FrameNum*100)/NumFrames);
			DoEvents();
			if (!WriteByte(0xFF))
			{
				CloseStatus();
				return FALSE;
			}
		}
	}
	if (!WriteByte(0x95) && !WriteByte(0x00))
	{
		CloseStatus();
		return FALSE;
	}
	fclose(REGDATA);
	StatusPercent(100);
	StatusText("...done!");
	StatusOK();
	ResetNES(RESET_COPYMODE);
	return TRUE;
}

BOOL	RegPlayVRC7 (char *filename)
{
	int FrameNum = 0, NumFrames = 0;
	FILE *REGDATA;
	OpenStatus(topHWnd);
	StatusText("Resetting USB CopyNES...");
	ResetNES(RESET_COPYMODE);
	StatusText("Loading plugin...");
	if (!LoadPlugin("rdump2.bin"))
	{
		CloseStatus();
		return FALSE;
	}
	StatusText("Initializing plugin...");
	RunCode();
	Sleep(SLEEP_SHORT);
	REGDATA = fopen(filename,"rt");
	StatusText("Playing...");
	StatusPercent(0);
	while (!feof(REGDATA))
	{
		char data[32];
		fscanf(REGDATA,"%[^\n]\n",data);
		if (!strncmp(data,"frame",5))
			NumFrames++;
	}
	rewind(REGDATA);
	while (!feof(REGDATA))
	{
		char data[32];
		fscanf(REGDATA,"%[^\n]\n",data);
		if (!strncmp(data,"90",2))
		{
			int Addr, Val;
			sscanf(data,"90%02X  %02X\n",&Addr,&Val);
			if (!WriteByte((BYTE)(0x80 | ((Val & 0x80) >> 1) | (Addr & 0x1F))) || !WriteByte((BYTE)(Val & 0x7F)))
			{
				CloseStatus();
				return FALSE;
			}
		}
		if (!strncmp(data,"frame",5))
		{
			FrameNum++;
			StatusPercent((FrameNum*100)/NumFrames);
			DoEvents();
			Sleep(16);	// wait about a frame or so
		}
	}
	if (!WriteByte(0x95) && !WriteByte(0x00))
	{
		CloseStatus();
		return FALSE;
	}
	fclose(REGDATA);
	StatusPercent(100);
	StatusText("...done!");
	StatusOK();
	ResetNES(RESET_COPYMODE);
	return TRUE;
}

BOOL	CMD_REGPLAY (void)
{
	int a;
	char filename[MAX_PATH];
	if (!PromptFile(topHWnd,"Register dumps (*.TXT;*.REG)\0*.txt;*.reg\0\0",filename,NULL,NULL,"Select a file...",NULL,FALSE))
		return FALSE;

	a = MessageBox(topHWnd,"What type of register dump is this?\nYES => Standard NES\nNO => VRC7",MSGBOX_TITLE,MB_YESNOCANCEL | MB_ICONQUESTION);
	if (a == IDYES)
		return RegPlayNES(filename);
	else if (a == IDNO)
		return RegPlayVRC7(filename);
	else	return FALSE;
}
