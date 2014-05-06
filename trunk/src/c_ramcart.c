#include "StdAfx.h"
#define	CMD_NAME	"RAM Cart"

BYTE header[16];
int mapper;
int PRG, CHR;

BOOL IsPowerOfTwo(int num)
{
	int i;
	i=num;
	while(i)
	{
		if((i&1) && (i&0xFFE))
			return FALSE;
		i>>=1;
	}
	return TRUE;
}


BOOL AssertPRG(int min, int max)
{

	if((PRG >= min) && (PRG <= max) && IsPowerOfTwo(PRG))
	{
		StatusText("%iKB PRG ROM data located...",PRG*16);
		return TRUE;
	}
	StatusText("Invalid PRG size, must be an even size between %iKB and %iKB!",min*16,max*16);
	return FALSE;
}

BOOL AssertCHR(int max)
{
	if (header[5] > max)
	{
		if(max > 0)
			StatusText("More than %iKB of CHR ROM data was detected, sending first %iKB only...",max*8,max*8);
		else
			StatusText("%iKB of CHR ROM data was detected, ignoring...", CHR * 8);
	}
	else
	{
		if(!IsPowerOfTwo(CHR))
		{
			StatusText("Invalid CHR ROM size (%iKB)!", CHR * 8);
			return FALSE;
		}
		StatusText("%iKB CHR ROM data located...",CHR*8);
	}
	return TRUE;
}

BOOL AssertMapper(int *mappers, int count)
{
	int i;
	for(i=0;i<count;i++)
		if(mappers[i] == mapper)
			return TRUE;
	if((MessageBox(topHWnd,"Incorrect iNES mapper detected! Load anyways?",MSGBOX_TITLE,MB_YESNO | MB_ICONQUESTION) == IDNO))
	{
		StatusText("Load aborted.");
		return FALSE;
	}
	return TRUE;
}

BOOL LoadPPlugin(PPlugin plugin)
{
	char *pluginfile = (plugin->load_nsf?plugin->nsffile:plugin->file);
	InitPort();
	StatusText("Resetting CopyNES...");
	ResetNES(RESET_COPYMODE);
	StatusText("Loading plugin...");
	if (!LoadPlugin(pluginfile))
	{
		StatusText("Plugin load failed!");
		return FALSE;
	}
	StatusText("Initializing plugin...");
	RunCode();
	Sleep(SLEEP_SHORT);
	return TRUE;
}

BOOL SendData(int amt, char *data)
{
	int j;
	for (j = 0; j < amt; j++)
	{
		if (!WriteBlock(data, 1024))
		{
			StatusText("Failed to send.");
			return FALSE;
		}
		data += 1024;
		StatusPercent((j * 100) / amt);
		DoEvents();
	}
	StatusPercent(100);
	StatusText("...done!");

	return TRUE;
}


BOOL	NRAMcart (PPlugin plugin, char* filedata)
{
	int PRGsize;
	BYTE PRGamt;
	char* data;
	int mappers[] = {0};

	if(!AssertPRG(1,2)) return FALSE;

	PRGamt = PRG-1;
	PRGsize = PRG*16384;

	if(AssertCHR(1)) return FALSE;
	if(!plugin->load_nsf)
	{
		if(!AssertMapper(mappers,sizeof(mappers)))
			return FALSE;

		if (header[6] & 1)
			MessageBox(topHWnd,"Please set your cartridge to VERTICAL mirroring.",MSGBOX_TITLE,MB_OK);
		else
			MessageBox(topHWnd,"Please set your cartridge to HORIZONTAL mirroring.",MSGBOX_TITLE,MB_OK);
	}

	if(!LoadPPlugin(plugin))
		return FALSE;

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
	SendData(header[4]*16,data);
	
	
	StatusText("Sending CHR data...");
	data = filedata + 16 + (header[4] * 16384); // CHR
	SendData(header[5]*8,data);

	return TRUE;
}


BOOL	CNRAMcart (PPlugin plugin, char* filedata)
{
	int maxchr = 4;
	int mappers[] = { 0, 3 };
	char* data;
	char *pluginfile = (plugin->load_nsf?plugin->nsffile:plugin->file);

	if(!AssertPRG(1,2))
		return FALSE;

	if (mapper == 0)
		maxchr = 1;

	if(!AssertCHR(maxchr)) return FALSE;
	

	if(!plugin->load_nsf)
	{
		if(!AssertMapper(mappers,sizeof(mappers)))
			return FALSE;
		if (header[6] & 1)
			MessageBox(topHWnd,"Please set your cartridge to VERTICAL mirroring.",MSGBOX_TITLE,MB_OK);
		else	MessageBox(topHWnd,"Please set your cartridge to HORIZONTAL mirroring.",MSGBOX_TITLE,MB_OK);
	}

	if(!LoadPPlugin(plugin))
		return FALSE;

	StatusText("Sending CHR data...");
	data = filedata + 16 + (header[4] * 16384); // CHR
	if (!WriteByte(header[5]))
	{
		StatusText("Failed to send!");
		return FALSE;
	}
	SendData(header[5]*8,data);

	StatusText("Sending PRG data...");
	if (!WriteByte(header[4]))
	{
		StatusText("Failed to send!");
		return FALSE;
	}
	data = filedata + 16; // PRG
	SendData(header[4]*16,data);
	
	StatusText("Write protect your cartridge, then press OK to run program...");
	StatusButton();
	if (!WriteByte(0x55) || !WriteByte(0xAA))
	{
		StatusText("Failed to send!");
		return FALSE;
	}

	return TRUE;
}


BOOL	UFROMcart (PPlugin plugin, char* filedata)
{
	int i;
	BYTE banks;
	char* data;
	int mappers[] = { 2 };
	
	if(!AssertPRG(1,16)) return FALSE;
	if(!AssertCHR(0)) return FALSE;

	if(!plugin->load_nsf)
	{
		if(!AssertMapper(mappers,sizeof(mappers))) return FALSE;
		if (header[6] & 1)
			MessageBox(topHWnd,"Please set your cartridge to VERTICAL mirroring.",MSGBOX_TITLE,MB_OK);
		else	MessageBox(topHWnd,"Please set your cartridge to HORIZONTAL mirroring.",MSGBOX_TITLE,MB_OK);
	}
	if(!LoadPPlugin(plugin)) return FALSE;

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
	for (banks = 0; banks < 16; banks += PRG )
	{
		data = filedata + 16; // PRG
		SendData(PRG*16,data);
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


BOOL	PowerPakLitecart (PPlugin plugin, char* filedata)
{
	int maxchr = 4;
	int maxprg = 0;
	BYTE config = 0;
	char* data;
	int mappers[] = { 0, 1, 2, 3, 7, 11, 34, 68 };
	

	if(plugin->load_nsf != 1)
	{
		if(!AssertMapper(mappers,sizeof(mappers)))
			return FALSE;
	}

	config = (header[4] - 1) * 16;
	switch(mapper)
	{
	case 0:
	default:
		config = config + 0;
		maxchr = 1;			//nrom  =    8KB chr
		maxprg = 2;			//nrom  =   32KB prg
		StatusText("NROM (iNES 0)");
		break;
	case 1:
		config = config + 1; 
		maxchr = 16;		//mmc1  =  128KB chr
		maxprg = 16;		//mmc1  =  256KB prg
		StatusText("MMC1 (iNES 1)");
		break;
	case 2:
		config = config + 2;
		maxchr = 0;			//urom  =    0KB chr
		maxprg = 16;		//urom  =  256KB prg
		StatusText("U*NROM (iNES 2)");
		break;
	case 3:
		config = config + 3;  
		maxchr = 4;          //cnrom =  32KB chr
		maxprg = 2;          //cnrom =  32KB prg
		StatusText("CNROM (iNES 3)");
		break;
	case 7:
		config = config + 4; 
		maxchr = 0;          //arom  =   0KB chr	  
		maxprg = 16;         //arom  = 256KB prg  
		StatusText("A*ROM (iNES 7)");
		break;
	case 11:
		config = config + 5; 
		maxchr = 16;         //color = 128KB chr	  
		maxprg = 8;          //color = 128KB prg  
		StatusText("ColorDreams (iNES 11)");
		break;
	case 34:
		config = config + 6; 
		maxchr = 0;          //bnrom =   0KB chr
		maxprg = 8;          //bnrom = 128KB prg
		StatusText("BNROM (iNES 34)");
		break;
	case 66:
		config = config + 7;  
		maxchr = 4;          //gnrom =  32KB chr    
		maxprg = 8;          //gnrom = 128KB prg   
		StatusText("GNROM (iNES 66)");
		break;
	}

	if(!AssertPRG(1,maxprg)) return FALSE;
	if(!AssertCHR(maxchr)) return FALSE;
	if(!LoadPPlugin(plugin)) return FALSE;
	
	StatusText("Sending PRG data...");
	if (!WriteByte(header[4]))
	{
		StatusText("Failed to send.");
		return FALSE;
	}
	data = filedata + 16; // PRG
	SendData(header[4]*16,data);

	StatusText("Sending CHR data...");
	data = filedata + 16 + (header[4] * 16384); // CHR
	if (!WriteByte(header[5]))
	{
		StatusText("Failed to send.");
		return FALSE;
	}
	SendData(header[5]*8,data);

	///SEND CONFIG PRG BYTE
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


BOOL	PowerPakcart (PPlugin plugin, char* filedata)
{
	int i;
	BYTE banks;
	char* data;
	int mappers[] = {2};

	if(!AssertPRG(4,4))
		return FALSE;
	AssertCHR(0);

	if(!AssertMapper(mappers,sizeof(mappers)))
		return FALSE;

	if(!LoadPPlugin(plugin))
		return FALSE;

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
		StatusText("Sending %i of 4.....",i+1);
		data = filedata + 16; // PRG
		SendData(64,data);
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


BOOL	Glidercart (PPlugin plugin, char* filedata)
{
	int i;
	BYTE banks;
	char* data;
	int mappers[] = { 13, 29 };	//13 is the mapper number on the upgrade files present on retrozone.
								//29 is the mapper number assigned to glider, at the time it was dumped.

	if(!AssertPRG(1,8))
		return FALSE;
	AssertCHR(0);
	if(plugin->load_nsf != 1)
		if(!AssertMapper(mappers,sizeof(mappers)))
			return FALSE;

	banks = header[4];

	if(!LoadPPlugin(plugin))
		return FALSE;

	StatusText("Erasing Flash ROM...");
	if (!WriteByte(banks))
	{
		StatusText("Failed to write");
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
	data = filedata + 16; // PRG
	SendData(banks*16,data);

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

BOOL	UNROM512cart (PPlugin plugin, char* filedata)
{
	BYTE a;
	BYTE bank, banks;
	char string[256];
	char* data;
	int mappers[] = { 2, 30 };

	if(!AssertPRG(1,32))
		return FALSE;
	AssertCHR(0);


	if(!plugin->load_nsf)
	{
		if(!AssertMapper(mappers,sizeof(mappers)))
			return FALSE;

		if (header[6] & 8)
			MessageBox(topHWnd,"Please set your cartridge to ONE Screen mirroring.\n(ONE jumper on sealie unrom512 board)",MSGBOX_TITLE,MB_OK);
		else if (header[6] & 1)
			MessageBox(topHWnd,"Please set your cartridge to VERTICAL mirroring. \n(HORIZ jumper on sealie unrom512 board)",MSGBOX_TITLE,MB_OK);
		else	MessageBox(topHWnd,"Please set your cartridge to HORIZONTAL mirroring.\n(VERT jumper on sealie unrom512 board)",MSGBOX_TITLE,MB_OK);
	}
	if(!LoadPPlugin(plugin))
		return FALSE;

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
	if(!WriteByte(header[4]))	//Send start signal to actually erase the cart.
	{
		StatusText("Failed to write!");
		return FALSE;
	}
	if (!ReadByte(&a))	//Wait for cart erase to be completed.
	{
		StatusText("Failed to read!");
		return FALSE;
	}
	if(a!=header[4])
	{
		StatusText("Failed to Erase Cart!");
		return FALSE;
	}
	StatusPercent(100);
	StatusText("...done!");

	StatusText("Sending data...");
	bank=0;
	data = filedata + 16; // PRG
	SendData(PRG*16,data);

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
	BOOL result;

	// select board name
	plugin = PromptPlugin(PLUG_UPLOAD);
	if (plugin == NULL)
		return FALSE;
	plugin->load_nsf = 0;

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

	mapper = ((header[6] & 0xF0) >> 4) | (header[7] & 0xF0);
	PRG = header[4];
	CHR = header[5];
	if((header[7] & 0x0C) == 0x08)
	{
		PRG |= ((header[9] & 0x0F) << 8);
		CHR |= ((header[9] & 0xF0) << 4);
		mapper |= ((header[8] & 0x0F) << 8);
	}

	result = FALSE;

	if (plugin->num == 0)
		result = NRAMcart(plugin, filedata);
	else if (plugin->num == 1)
		result = CNRAMcart(plugin, filedata);
	else if (plugin->num == 2)
		result = UFROMcart(plugin, filedata);
	else if (plugin->num == 3)
		result = PowerPakLitecart(plugin, filedata);
	else if (plugin->num == 4)
		result = PowerPakcart(plugin, filedata);
	else if (plugin->num == 5)
		result = Glidercart(plugin, filedata);
	else if (plugin->num == 6)
		result = UNROM512cart(plugin, filedata);
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

BOOL	RAMCartLoad (char* filedata, long int filesize, int load_type)
{
	PPlugin plugin;
	BOOL result;

	// select board name
	plugin = PromptPlugin(PLUG_UPLOAD);
	if (plugin == NULL)
		return FALSE;

	if((load_type == 1) && (plugin->nsffile == NULL))
	{
		StatusText("Selected plugin does not support loading NSF!");
		return FALSE;
	}
	plugin->load_nsf = (load_type == 1);
	
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

	mapper = ((header[6] & 0xF0) >> 4) | (header[7] & 0xF0);
	PRG = header[4];
	CHR = header[5];
	if((header[7] & 0x0C) == 0x08)
	{
		PRG |= ((header[9] & 0x0F) << 8);
		CHR |= ((header[9] & 0xF0) << 4);
		mapper |= ((header[8] & 0x0F) << 8);
	}

	result = FALSE;

	if (plugin->num == 0)
		result = NRAMcart(plugin, filedata);
	else if (plugin->num == 1)
		result = CNRAMcart(plugin, filedata);
	else if (plugin->num == 2)
		result = UFROMcart(plugin, filedata);
	else if (plugin->num == 3)
		result = PowerPakLitecart(plugin, filedata);
	else if (plugin->num == 4)
		result = PowerPakcart(plugin, filedata);
	else if (plugin->num == 5)
		result = Glidercart(plugin, filedata);
	else if (plugin->num == 6)
		result = UNROM512cart(plugin, filedata);
	else	
		result = FALSE;

	return result;
}
