#include "StdAfx.h"
#define	CMD_NAME	"RAM Cart"


BOOL	NRAMcart (char* plugin, char* filedata)
{
	int i, j, PRGsize;
	BYTE PRGamt;
	BYTE header[16];
	BYTE mapper;
	char* data;

	memcpy(header,filedata,16);
	if (header[4] == 2)
	{
		PRGamt = 0;
		PRGsize = 32768;
		StatusText("32KB PRG ROM data located...");
	}
	else if (header[4] == 1)
	{
		PRGamt = 1;
		PRGsize = 16384;
		StatusText("16KB PRG ROM data located...");
	}
	else
	{
		StatusText("Invalid PRG size, must be 16KB or 32KB!");
		return FALSE;
	}

	if (header[5] > 1)
		StatusText("More than 8KB of CHR ROM data was detected, sending first 8KB only...");
	else	StatusText("8KB CHR ROM data located...");

	mapper = ((header[6] & 0xF0) >> 4) | (header[7] & 0xF0);
	if ((mapper != 0) && (MessageBox(topHWnd,"Incorrect iNES mapper detected! Load anyways?",MSGBOX_TITLE,MB_YESNO | MB_ICONQUESTION) == IDNO))
	{
		StatusText("Load aborted.");
		return FALSE;
	}

	if (header[6] & 1)
		MessageBox(topHWnd,"Please set your cartridge to VERTICAL mirroring.",MSGBOX_TITLE,MB_OK);
	else
		MessageBox(topHWnd,"Please set your cartridge to HORIZONTAL mirroring.",MSGBOX_TITLE,MB_OK);

	StatusText("Resetting USB CopyNES...");
	ResetNES(RESET_COPYMODE);
	StatusText("Loading plugin...");
	if (!LoadPlugin(plugin))
	{
		StatusText("Plugin load failed!");
		return FALSE;
	}
	StatusText("Initializing plugin...");
	RunCode();
	Sleep(SLEEP_SHORT);
	if (!WriteByte(PRGamt))
	{
		StatusText("Failed to send.");
		return FALSE;
	}
	
	StatusText("Sending PRG data...");
	if (!WriteByte(header[4]))
	{
		StatusText("Failed to send.");
		return FALSE;
	}
	data = filedata + 16; // PRG
	for (i = 0; i < header[4]; i++)
	{
		for (j = 0; j < 16; j++)
		{
			if (!WriteBlock(data, 1024))
			{
				StatusText("Failed to send.");
				return FALSE;
			}
			data += 1024;
			StatusPercent(((i * 16 + j) * 100) / (header[4] * 16));
			DoEvents();
		}
	}
	StatusPercent(100);
	StatusText("...done!");
	
	StatusText("Sending CHR data...");
	data = filedata + 16 + (header[4] * 16384); // CHR
	for (i = 0; i < header[5]; i++)
	{
		for (j = 0; j < 8; j++)
		{
			if (!WriteBlock(data, 1024))
			{
				StatusText("Failed to send.");
				return FALSE;
			}
			data += 1024;
			StatusPercent(((i * 8 + j) * 100) / (header[5] * 8));
			DoEvents();
		}
	}
	StatusPercent(100);
	StatusText("...done!");

	return TRUE;
}


BOOL	CNRAMcart (char* plugin, char* filedata)
{
	int i, j;
	BYTE header[16];
	BYTE mapper;
	int maxchr = 4;
	char* data;

	memcpy(header,filedata,16);
	if ((header[4]) && (header[4] <= 2))
		StatusText("%iKB PRG ROM data located...", header[4] * 16);
	else
	{
		StatusText("Invalid PRG size, must be 16KB or 32KB!");
		return FALSE;
	}

	mapper = ((header[6] & 0xF0) >> 4) | (header[7] & 0xF0);
	if (mapper == 0)
		maxchr = 1;

	if (header[5] > maxchr)
		StatusText("More than %iKB of CHR ROM data was detected, sending first %iKB only...", maxchr * 8, maxchr * 8);
	else if (header[5] == 3)
	{
		StatusText("Invalid CHR ROM size (%iKB)!", maxchr * 8);
		return FALSE;
	}
	else	StatusText("%iKB CHR ROM data located...", header[5] * 8);

	if ((mapper != 0) && (mapper != 3) && (MessageBox(topHWnd,"Incorrect iNES mapper detected! Load anyways?",MSGBOX_TITLE,MB_YESNO | MB_ICONQUESTION) == IDNO))
	{
		StatusText("Load aborted.");
		return FALSE;
	}
	if (header[6] & 1)
		MessageBox(topHWnd,"Please set your cartridge to VERTICAL mirroring.",MSGBOX_TITLE,MB_OK);
	else	MessageBox(topHWnd,"Please set your cartridge to HORIZONTAL mirroring.",MSGBOX_TITLE,MB_OK);

	StatusText("Resetting USB CopyNES...");
	ResetNES(RESET_COPYMODE);
	StatusText("Loading plugin...");
	if (!LoadPlugin(plugin))
	{
		StatusText("Plugin load failed!");
		return FALSE;
	}
	StatusText("Initializing plugin...");
	RunCode();
	Sleep(SLEEP_SHORT);

	StatusText("Sending CHR data...");
	data = filedata + 16 + (header[4] * 16384); // CHR
	if (!WriteByte(header[5]))
	{
		StatusText("Failed to send!");
		return FALSE;
	}
	for (i = 0; i < header[5]; i++)
	{
		for (j = 0; j < 8; j++)
		{
			if (!WriteBlock(data, 1024))
			{
				StatusText("Failed to send!");
				return FALSE;
			}
			data += 1024;
			StatusPercent(((i * 8 + j) * 100) / (header[5] * 8));
			DoEvents();
		}
	}
	StatusPercent(100);
	StatusText("...done!");

	StatusText("Sending PRG data...");
	if (!WriteByte(header[4]))
	{
		StatusText("Failed to send!");
		return FALSE;
	}
	data = filedata + 16; // PRG
	for (i = 0; i < header[4]; i++)
	{
		for (j = 0; j < 16; j++)
		{
			if (!WriteBlock(data, 1024))
			{
				StatusText("Failed to send!");
				return FALSE;
			}
			data += 1024;
			StatusPercent(((i * 16 + j) * 100) / (header[4] * 16));
			DoEvents();
		}
	}
	StatusPercent(100);
	StatusText("...done!");
	
	StatusText("Write protect your cartridge, then press OK to run program...");
	StatusButton();
	if (!WriteByte(0x55) || !WriteByte(0xAA))
	{
		StatusText("Failed to send!");
		return FALSE;
	}

	return TRUE;
}


BOOL	UFROMcart (char* plugin, char* filedata)
{
	int i, j;
	BYTE header[16];
	BYTE mapper;
	BYTE banks;
	char* data;

	memcpy(header,filedata,16);
	if ((header[4] == 1) || (header[4] == 2) || (header[4] == 4) || (header[4] == 8) || (header[4] == 16))
		StatusText("%iKB PRG ROM data located...", header[4] * 16);
	else
	{
		StatusText("Invalid PRG size, must be an even amount between 16KB and 256KB!");
		return FALSE;
	}

	mapper = ((header[6] & 0xF0) >> 4) | (header[7] & 0xF0);

	if (header[5] > 0)
		StatusText("%iKB of CHR ROM data was detected, ignoring...", header[5] * 8);

	if ((mapper != 2) && (MessageBox(topHWnd,"Incorrect iNES mapper detected! Load anyways?",MSGBOX_TITLE,MB_YESNO | MB_ICONQUESTION) == IDNO))
	{
		StatusText("Load aborted.");
		return FALSE;
	}
	if (header[6] & 1)
		MessageBox(topHWnd,"Please set your cartridge to VERTICAL mirroring.",MSGBOX_TITLE,MB_OK);
	else	MessageBox(topHWnd,"Please set your cartridge to HORIZONTAL mirroring.",MSGBOX_TITLE,MB_OK);

	StatusText("Resetting USB CopyNES...");
	ResetNES(RESET_COPYMODE);
	StatusText("Loading plugin...");
	if (!LoadPlugin(plugin))
	{
		StatusText("Plugin load failed!");
		return FALSE;
	}
	StatusText("Initializing plugin...");
	RunCode();
	Sleep(SLEEP_SHORT);

	StatusText("Erasing Flash ROM...");
	if (!ReadByte(&banks))
	{
		StatusText("Failed to read!");
		return FALSE;
	}
	for (i = 0; i < banks; i++)
	{
		BYTE a;
		if (!ReadByte(&a))
		{
			StatusText("Failed to read!");
			return FALSE;
		}
		StatusPercent(100 * i / banks);
		DoEvents();
	}
	StatusPercent(100);
	StatusText("...done!");

	StatusText("Sending data...");
	for (banks = 0; banks < 16; )
	{
		data = filedata + 16; // PRG
		for (i = 0; i < header[4]; i++, banks++)
		{
			for (j = 0; j < 16; j++)
			{
				if (!WriteBlock(data, 1024))
				{
					StatusText("Failed to send!");
					return FALSE;
				}
				data += 1024;
				StatusPercent(((banks * 16 + j) * 100) / 256);
				DoEvents();
			}
		}
	}
	StatusPercent(100);
	StatusText("...done!");

	if (!ReadByte(&banks))
	{
		StatusText("Failed to read!");
		return FALSE;
	}
	if (banks != 0)
	{
		StatusText("An error occurred while writing to the cartridge!");
		return FALSE;
	}

	return TRUE;
}


BOOL	PowerPakLitecart (char* plugin, char* filedata)
{
	int i, j;
	BYTE header[16];
	BYTE mapper;
	int maxchr = 4;
	int maxprg = 0;
	BYTE config = 0;
	char* data;

	memcpy(header,filedata,16);

	mapper = ((header[6] & 0xF0) >> 4) | (header[7] & 0xF0);
	if ((mapper != 0) && (mapper != 1) && (mapper != 2) && (mapper != 3) && 
		(mapper != 7) && (mapper != 11) && (mapper != 34) && (mapper != 66) && 
		(MessageBox(topHWnd,"Incorrect iNES mapper detected! Load anyways?",MSGBOX_TITLE,MB_YESNO | MB_ICONQUESTION) == IDNO))
	{
		StatusText("Load aborted.");
		return FALSE;
	}

	if (mapper == 0)
	{
		maxchr = 1;          //nrom  =   8KB chr
		maxprg = 2;          //nrom  =  32KB prg
		StatusText("NROM (iNES 0)");
	}
	else if (mapper == 1)
	{
		maxchr = 16;         //mmc1  = 128KB chr
		maxprg = 16;         //mmc1  = 256KB prg
		StatusText("MMC1 (iNES 1)");
	}
 	else if (mapper == 2)
 	{
		maxchr = 0;          //urom  =   0KB chr
		maxprg = 16;         //urom  = 256KB prg
		StatusText("U*NROM (iNES 2)");
	}
	else if (mapper == 3)
	{
		maxchr = 4;          //cnrom =  32KB chr
		maxprg = 2;          //cnrom =  32KB prg
		StatusText("CNROM (iNES 3)");
	}
	else if (mapper == 7)
	{
		maxchr = 0;          //arom  =   0KB chr	  
		maxprg = 16;         //arom  = 256KB prg  
		StatusText("A*ROM (iNES 7)");
	}
	else if (mapper == 11)
	{
		maxchr = 16;         //color = 128KB chr	  
		maxprg = 8;          //color = 128KB prg  
		StatusText("ColorDreams (iNES 11)");
	}
	else if (mapper == 34)
	{
		maxchr = 0;          //bnrom =   0KB chr
		maxprg = 8;          //bnrom = 128KB prg
		StatusText("BNROM (iNES 34)");
	}
	else if (mapper == 66)
	{
		maxchr = 4;          //gnrom =  32KB chr    
		maxprg = 8;          //gnrom = 128KB prg   
		StatusText("GNROM (iNES 66)");
	}

	if (header[4] > maxprg)
	{
		StatusText("Invalid PRG size, more than %iKB of PRG ROM data was detected!", maxprg * 8);
		return FALSE;
	}
	else
		StatusText("%iKB PRG ROM data located...", header[4] * 16);
	
	if (header[5] > maxchr)
		StatusText("More than %iKB of CHR ROM data was detected, sending first %iKB only...", maxchr * 8, maxchr * 8);
	else
		StatusText("%iKB CHR ROM data located...", header[5] * 8);

	StatusText("Resetting USB CopyNES...");
	ResetNES(RESET_COPYMODE);
	StatusText("Loading plugin...");
	if (!LoadPlugin(plugin))
	{
		StatusText("Plugin load failed!");
		return FALSE;
	}
	StatusText("Initializing plugin...");
	RunCode();
	Sleep(SLEEP_SHORT);
	
	StatusText("Sending PRG data...");
	if (!WriteByte(header[4]))
	{
		StatusText("Failed to send.");
		return FALSE;
	}
	data = filedata + 16; // PRG
	for (i=0; i<header[4]; i++)
	{
		for (j=0; j<16; j++)
		{
			if (!WriteBlock(data, 1024))
			{
				StatusText("Failed to send.");
				return FALSE;
			}
			data += 1024;
			StatusPercent(((i * 16 + j) * 100) / (header[4] * 16));     
			DoEvents();
		}
	}
	
	StatusPercent(100);
	StatusText("...done!");	

	StatusText("Sending CHR data...");
	data = filedata + 16 + (header[4] * 16384); // CHR
	if (!WriteByte(header[5]))
	{
		StatusText("Failed to send.");
		return FALSE;
	}
	for (i = 0; i < header[5]; i++)
	{
		for (j = 0; j < 8; j++)
		{
			if (!WriteBlock(data, 1024))
			{
				StatusText("Failed to send.");
				return FALSE;
			}
			data += 1024;
			StatusPercent(((i * 8 + j) * 100) / (header[5] * 8));
			DoEvents();
		}
	}
	StatusPercent(100);
	StatusText("...done!");


	///SEND CONFIG PRG BYTE
	config = (header[4] - 1) * 16;
	if (mapper == 0) config = config + 0;
	if (mapper == 1) config = config + 1;  
	if (mapper == 2) config = config + 2;
	if (mapper == 3) config = config + 3;  
	if (mapper == 7) config = config + 4;  
	if (mapper == 11) config = config + 5;  
	if (mapper == 34) config = config + 6;  
	if (mapper == 66) config = config + 7;  

	StatusText("config 1 = %i", config); 

	if (!WriteByte(config))
	{
		StatusText("Failed to send.");
		return FALSE;
	}

	///SEND CONFIG CHR BYTE
	config = (header[5] - 1);
	if (header[5] == 0)
		config = 32;     //chr ram enable bit
	if (header[6] & 1)  //mirror=1
		config = config + 16;

		StatusText("config 2 = %i", config); 

	if (!WriteByte(config))
	{
		StatusText("Failed to send.");
		return FALSE;
	}

	//if (!WriteByte(0x55) || !WriteByte(0xAA))
	//{
	//	return FALSE;
	//}

	return TRUE;
}


BOOL	PowerPakcart (char* plugin, char* filedata)
{
	int i, j;
	BYTE header[16];
	BYTE mapper;
	BYTE banks;
	char* data;

	memcpy(header,filedata,16);

	if (header[4] == 4)
		StatusText("%iKB PRG ROM data located...", header[4] * 16);
	else
	{
		StatusText("Invalid PRG size, must be 64KB PRG!");
		return FALSE;
	}

	mapper = ((header[6] & 0xF0) >> 4) | (header[7] & 0xF0);

	if (header[5] > 0)
		StatusText("%iKB of CHR ROM data was detected, ignoring...", header[5] * 8);

	if ((mapper != 2) && (MessageBox(topHWnd,"Incorrect iNES mapper detected! Load anyways?",MSGBOX_TITLE,MB_YESNO | MB_ICONQUESTION) == IDNO))
	{
		StatusText("Load aborted.");
		return FALSE;
	}

	StatusText("Resetting USB CopyNES...");
	ResetNES(RESET_COPYMODE);
	StatusText("Loading plugin...");
	if (!LoadPlugin(plugin))
	{
		StatusText("Plugin load failed!");
		return FALSE;
	}
	StatusText("Initializing plugin...");
	RunCode();
	Sleep(SLEEP_SHORT);

	StatusText("Erasing Flash ROM...");
	if (!ReadByte(&banks))
	{
		StatusText("Failed to read.");
		return FALSE;
	}
	for (i = 0; i < banks; i++)
	{
		BYTE a;
		if (!ReadByte(&a))
		{
			StatusText("Failed to send.");
			return FALSE;
		}
		StatusPercent(100 * i / banks);
		DoEvents();
	}
	StatusPercent(100);
	StatusText("...done!");

	StatusText("Sending PRG data...");
	
	for (i=0; i<4; i++)
	{
		data = filedata + 16; // PRG
		for (j=0; j<64; j++)
		{
			if (!WriteBlock(data, 1024))
			{
				StatusText("Failed to send.");
				return FALSE;
			}
			data += 1024;
			StatusPercent(((i*64 + j) * 100) / 256);   
			DoEvents();
		}
	}
	
	StatusPercent(100);
	StatusText("...done!");	

	if (!ReadByte(&banks))
	{
		StatusText("Failed to read.");
		return FALSE;
	}
	if (banks != 0)
	{
		StatusText("An error occurred while writing to the cartridge!");
		return FALSE;
	}

	return TRUE;
}


BOOL	Glidercart (char* plugin, char* filedata)
{
	int i, j;
	BYTE header[16];
	BYTE mapper;
	BYTE banks;
	char* data;

	memcpy(header,filedata,16);

	mapper = ((header[6] & 0xF0) >> 4) | (header[7] & 0xF0);

	if (header[5] > 0)
		StatusText("%iKB of CHR ROM data was detected, ignoring...", header[5] * 8);

	StatusText("Resetting USB CopyNES...");
	ResetNES(RESET_COPYMODE);
	StatusText("Loading plugin...");
	if (!LoadPlugin(plugin))
	{
		StatusText("Plugin load failed!");
		return FALSE;
	}
	StatusText("Initializing plugin...");
	RunCode();
	Sleep(SLEEP_SHORT);

	StatusText("Erasing Flash ROM...");
	if (!ReadByte(&banks))
	{
		StatusText("Failed to read.");
		return FALSE;
	}
	for (i = 0; i < banks; i++)
	{
		BYTE a;
		if (!ReadByte(&a))
		{
			StatusText("Failed to send.");
			return FALSE;
		}
		StatusPercent(100 * i / banks);
		DoEvents();
	}
	StatusPercent(100);
	StatusText("...done!");

	StatusText("Sending PRG data...");
	
	for (i=0; i<4; i++)
	{
		data = filedata + 16; // PRG
		for (j=0; j<64; j++)
		{
			if (!WriteBlock(data, 1024))
			{
				StatusText("Failed to send.");
				return FALSE;
			}
			data += 1024;
			StatusPercent(((i*64 + j) * 100) / 256);   
			DoEvents();
		} 
	}
	
	StatusPercent(100);
	StatusText("...done!");	

	if (!ReadByte(&banks))
	{
		StatusText("Failed to read.");
		return FALSE;
	}
	if (banks != 0)
	{
		StatusText("An error occurred while writing to the cartridge!");
		return FALSE;
	}

	return TRUE;
}

BOOL	UNROM512cart (char* plugin, char* filedata)
{
	int i, j;
	BYTE header[16];
	BYTE mapper, a;
	BYTE bank, banks;
	char string[256];
	char* data;

	memcpy(header,filedata,16);
	if ((header[4] == 1) || (header[4] == 2) || (header[4] == 4) || (header[4] == 8) || (header[4] == 16) || (header[4] == 32))
		StatusText("%iKB PRG ROM data located...", header[4] * 16);
	else
	{
		StatusText("Invalid PRG size, must be an even amount between 16KB and 512KB!");
		return FALSE;
	}

	mapper = ((header[6] & 0xF0) >> 4) | (header[7] & 0xF0);

	if (header[5] > 0)
		StatusText("%iKB of CHR ROM data was detected, ignoring...", header[5] * 8);

	if (!((mapper == 30) || (mapper == 2)) && (MessageBox(topHWnd,"Incorrect iNES mapper detected! Load anyways?",MSGBOX_TITLE,MB_YESNO | MB_ICONQUESTION) == IDNO))
	{
		StatusText("Load aborted.");
		return FALSE;
	}

	if (header[6] & 8)
		MessageBox(topHWnd,"Please set your cartridge to ONE Screen mirroring.\n(ONE jumper on sealie unrom512 board)",MSGBOX_TITLE,MB_OK);
	else if (header[6] & 1)
		MessageBox(topHWnd,"Please set your cartridge to VERTICAL mirroring. \n(HORIZ jumper on sealie unrom512 board)",MSGBOX_TITLE,MB_OK);
	else	MessageBox(topHWnd,"Please set your cartridge to HORIZONTAL mirroring.\n(VERT jumper on sealie unrom512 board)",MSGBOX_TITLE,MB_OK);

	StatusText("Resetting USB CopyNES...");
	ResetNES(RESET_COPYMODE);
	StatusText("Loading plugin...");
	if (!LoadPlugin(plugin))
	{
		StatusText("Plugin load failed!");
		return FALSE;
	}
	StatusText("Initializing plugin...");
	RunCode();
	Sleep(SLEEP_SHORT);

	StatusText("Erasing Flash ROM...");
	banks=32;
	if (!WriteByte(banks))	//Start of plugin.
	{
		StatusText("Failed to write!");
		return FALSE;
	}
	if(!ReadByte(&banks))	//Get actual number of banks, confirmed by manufacturer/chip ID.
	{
		StatusText("Failed to read!");
		return FALSE;
	}
	if(banks == 0)	//If Banks was 0, then the manufacturer/chip ID was not recognized.
	{				//If you get this error, and you have an actual flash cart, then I will need to know these ID numbers.
		BYTE low_id, high_id;
		if(!ReadByte(&low_id))	//Manufacturer ID
		{
			StatusText("Failed to read!");
			return FALSE;
		}
		if(!ReadByte(&high_id))	//Chip ID
		{
			StatusText("Failed to read!");
			return FALSE;
		}
		sprintf(string,"Unrecognized flash device: Manufacturer ID = 0x%.2X, Chip ID = 0x%.2X",low_id,high_id);
		StatusText(string);
		return FALSE;
	}
	if(banks < header[4])	//Now that we confirmed the actual flash cart size, we just check to make sure the rom WILL fit this cart.
	{
		StatusText("Rom selected is too large for this flash cart");
		return FALSE;
	}
	if(!WriteByte(banks))	//Send start signal to actually erase the cart.
	{
		StatusText("Failed to write!");
		return FALSE;
	}
	if (!ReadByte(&a))	//Wait for cart erase to be completed.
	{
		StatusText("Failed to read!");
		return FALSE;
	}
	if(a!=banks)
	{
		StatusText("Failed to Erase Cart!");
		return FALSE;
	}
	StatusPercent(100);
	StatusText("...done!");

	StatusText("Sending data...");
	for (bank = 0; bank < banks; )
	{
		data = filedata + 16; // PRG
		for (i = 0; i < header[4]; i++, bank++)
		{
			for (j = 0; j < 16; j++)
			{
				if (!WriteBlock(data, 1024))
				{
					StatusText("Failed to send!");
					return FALSE;
				}
				data += 1024;
				StatusPercent(((bank * 16 + j) * 100) / 512);
				DoEvents();
			}
			if((header[4]==2) && (bank < 30))
			{
				banks++;	//Code to force the lower 16KB bank to fill every flash bank, except the last one.
				break;
			}
		}
	}
	StatusPercent(100);
	StatusText("...done!");

	if (!ReadByte(&banks))
	{
		StatusText("Failed to read!");
		return FALSE;
	}
	if (banks != 0)
	{
		StatusText("An error occurred while writing to the cartridge!");
		return FALSE;
	}

	return TRUE;
}


BOOL	CMD_RAMCART (void)
{
	PPlugin plugin;
	char filenes[MAX_PATH];
	FILE *NES;
	long filesize;
	char *filedata;
	BYTE header[16];
	BOOL result;

	// select board name
	plugin = PromptPlugin(PLUG_UPLOAD);
	if (plugin == NULL)
		return FALSE;

	// select NES file
	if (!PromptFile(topHWnd,"iNES ROM images (*.NES)\0*.nes\0\0",filenes,NULL,Path_NES,"Select an iNES ROM...","nes",FALSE))
		return FALSE;

	// open status window
	OpenStatus(topHWnd);

	if ((NES = fopen(filenes,"rb")) == NULL)
	{
		MessageBox(topHWnd,"Unable to open file!",MSGBOX_TITLE,MB_OK | MB_ICONERROR);
		CloseStatus();
		return FALSE;
	}

	// determine file size
	fseek(NES,0,SEEK_END);
	filesize = ftell(NES);
	fseek(NES,0,SEEK_SET);

	if (filesize < 16)
	{
		MessageBox(topHWnd,"NES file is too small to contain iNES header!",MSGBOX_TITLE,MB_OK | MB_ICONERROR);
		fclose(NES);
		CloseStatus();
		return FALSE;
	}

	// some plugins require 64k of data always
	filedata = malloc( (filesize<(16+(64*1024))) ? (16+(64*1024)) : filesize);

	if (filedata == NULL)
	{
		MessageBox(topHWnd,"Out of memory loading NES!",MSGBOX_TITLE,MB_OK | MB_ICONERROR);
		fclose(NES);
		CloseStatus();
		return FALSE;
	}

	fread(filedata,1,filesize,NES);
	memcpy(header,filedata,16);
	fclose(NES);

	if (memcmp(header,"NES\x1A",4))
	{
		StatusText("Selected file is not an iNES ROM image!");
		StatusOK();
		free(filedata);
		return FALSE;
	}

	if (filesize < (16 + (header[4] * 16384) + (header[5] * 8192)))
	{
		StatusText("NES file is too small to contain specified PRG/CHR data!");
		StatusOK();
		free(filedata);
		return FALSE;
	}

	result = FALSE;

	if (plugin->num == 0)
		result = NRAMcart(plugin->file, filedata);
	else if (plugin->num == 1)
		result = CNRAMcart(plugin->file, filedata);
	else if (plugin->num == 2)
		result = UFROMcart(plugin->file, filedata);
	else if (plugin->num == 3)
		result = PowerPakLitecart(plugin->file, filedata);
	else if (plugin->num == 4)
		result = PowerPakcart(plugin->file, filedata);
	else if (plugin->num == 5)
		result = Glidercart(plugin->file, filedata);
	else if (plugin->num == 6)
		result = UNROM512cart(plugin->file, filedata);
	else	
		result = FALSE;

	free(filedata);

	if (result == TRUE)
	{
		StatusText("Program running - Press OK to exit.");
		ResetNES(RESET_PLAYMODE | RESET_NORESET);
		StatusOK();
		ResetNES(RESET_COPYMODE);
	}
	else
	{
		StatusOK();
	}

	return result;
}

BOOL	RAMCartLoad (char* filedata, long int filesize)
{
	PPlugin plugin;
	BYTE header[16];
	BOOL result;

	// select board name
	plugin = PromptPlugin(PLUG_UPLOAD);
	if (plugin == NULL)
		return FALSE;

	if (filesize < 16)
	{
		StatusText("NES file is too small to contain iNES header!");
		return FALSE;
	}

	memcpy(header,filedata,16);

	if (memcmp(header,"NES\x1A",4))
	{
		StatusText("Selected file is not an iNES ROM image!");
		return FALSE;
	}

	if (filesize < (16 + (header[4] * 16384) + (header[5] * 8192)))
	{
		StatusText("NES file is too small to contain specified PRG/CHR data!");
		return FALSE;
	}

	result = FALSE;

	if (plugin->num == 0)
		result = NRAMcart(plugin->file, filedata);
	else if (plugin->num == 1)
		result = CNRAMcart(plugin->file, filedata);
	else if (plugin->num == 2)
		result = UFROMcart(plugin->file, filedata);
	else if (plugin->num == 3)
		result = PowerPakLitecart(plugin->file, filedata);
	else if (plugin->num == 4)
		result = PowerPakcart(plugin->file, filedata);
	else if (plugin->num == 5)
		result = Glidercart(plugin->file, filedata);
	else if (plugin->num == 6)
		result = UNROM512cart(plugin->file, filedata);
	else	
		result = FALSE;

	return result;
}
