#include "StdAfx.h"
#include <shlobj.h>

int	HWVer;
int	ParPort, ParAddr, ParECP;
BOOL	SaveCRC, SaveFiles, MakeUnif;
char	Path_MAIN[MAX_PATH], Path_PRG[MAX_PATH], Path_CHR[MAX_PATH], Path_WRAM[MAX_PATH],
	Path_NES[MAX_PATH], Path_CRC[MAX_PATH], Path_NSF[MAX_PATH], Path_PLUG[MAX_PATH];

/* Note: base path must have a trailing backslash */
char *	_relpath (char *abspath, char *basepath)
{
	int i, j, k;
	char tmp[MAX_PATH];
	tmp[0] = 0;
	i = 0;

	// this relative path finder can't deal with ..\ or .\, don't mangle the string in this case
	if (strstr(basepath,".\\") != NULL || strstr(abspath,".\\") != NULL)
	{
		return abspath;
	}

	while ((tolower(abspath[i]) == tolower(basepath[i])) && (basepath[i] != 0))
		i++;
	if (basepath[i])
	{
		k = 1;
		for (j = i; basepath[j] != 0; j++)
			if (basepath[j] == '\\')
				k++;
		for (j = 1; j < k; j++)
			strcat(tmp,"..\\");
	}
	strcat(tmp,&abspath[i]);
	if (strlen(tmp) == 0)
		strcpy(tmp,".");
	strcpy(abspath,tmp);
	return abspath;
}
char *	addSlash (char *path)
{
	int x = strlen(path);
	if (path[x-1] == '\\')
		return path;
	path[x] = '\\';
	path[x+1] = 0;
	return path;
}

void	GetProgPath (void)
{
	int i;
	GetModuleFileName(NULL,Path_MAIN,MAX_PATH);
	i = strlen(Path_MAIN);
	while (i > 0)
		if (Path_MAIN[--i] == '\\')
		{
			Path_MAIN[++i] = 0;
			return;
		}
}

void	GetConfig (void)
{
	char Config[MAX_PATH], tmpdir[MAX_PATH], tmpstr[16];
	strcpy(Config,Path_MAIN);
	strcat(Config,"USB CopyNES.ini");
	SaveCRC = GetPrivateProfileInt("USB CopyNES","SaveCRC",0,Config);
	SaveFiles = GetPrivateProfileInt("USB CopyNES","SaveFiles",0,Config);
	MakeUnif = GetPrivateProfileInt("USB CopyNES","MakeUnif",0,Config);
	GetPrivateProfileString("USB CopyNES","PRGPath","Parts",Path_PRG,MAX_PATH,Config);
	GetPrivateProfileString("USB CopyNES","CHRPath","Parts",Path_CHR,MAX_PATH,Config);
	GetPrivateProfileString("USB CopyNES","WRAMPath","Finished",Path_WRAM,MAX_PATH,Config);
	GetPrivateProfileString("USB CopyNES","NESPath","Finished",Path_NES,MAX_PATH,Config);
	GetPrivateProfileString("USB CopyNES","CRCPath","CRC",Path_CRC,MAX_PATH,Config);
	GetPrivateProfileString("USB CopyNES","NSFPath","NSF",Path_NSF,MAX_PATH,Config);
	GetPrivateProfileString("USB CopyNES","PluginPath","Plugdone",Path_PLUG,MAX_PATH,Config);
	strcpy(Path_PRG,addSlash(_fullpath(strcpy(tmpdir,Path_MAIN),Path_PRG,MAX_PATH)));
	strcpy(Path_CHR,addSlash(_fullpath(strcpy(tmpdir,Path_MAIN),Path_CHR,MAX_PATH)));
	strcpy(Path_WRAM,addSlash(_fullpath(strcpy(tmpdir,Path_MAIN),Path_WRAM,MAX_PATH)));
	strcpy(Path_NES,addSlash(_fullpath(strcpy(tmpdir,Path_MAIN),Path_NES,MAX_PATH)));
	strcpy(Path_CRC,addSlash(_fullpath(strcpy(tmpdir,Path_MAIN),Path_CRC,MAX_PATH)));
	strcpy(Path_NSF,addSlash(_fullpath(strcpy(tmpdir,Path_MAIN),Path_NSF,MAX_PATH)));
	strcpy(Path_PLUG,addSlash(_fullpath(strcpy(tmpdir,Path_MAIN),Path_PLUG,MAX_PATH)));
	ParPort = GetPrivateProfileInt("USB CopyNES","ParPort",0,Config);
	GetPrivateProfileString("USB CopyNES","ParAddr","0",tmpstr,16,Config);
	sscanf(tmpstr,"%X",&ParAddr);
	GetPrivateProfileString("USB CopyNES","ParECP","0",tmpstr,16,Config);
	sscanf(tmpstr,"%X",&ParECP);
	if ((ParPort > 0) && (ParAddr == 0))
	{
		// update old config data
		if (ParPort == 1)
			ParAddr = 0x378;
		if (ParPort == 2)
			ParAddr = 0x278;
		if (ParPort == 3)
			ParAddr = 0x3BC;
		if ((ParPort == 4) || (ParPort == 9))
			ParAddr = 0xD800;
		if (ParPort == 5)
			ParAddr = 0xE000;
		if (ParPort == 6)
			ParAddr = 0xE800;
		if (ParPort > 4)
			ParPort = 4;
		WriteConfig();
	}
	if ((ParAddr > 0) && (ParECP == 0))
	{
		ParECP = 0x400;
		WriteConfig();
	}
}
void	WriteConfig (void)
{
	char Config[MAX_PATH], tmpdir[MAX_PATH], tmpstr[16];
	strcpy(Config,Path_MAIN);
	strcat(Config,"USB CopyNES.ini");
	sprintf(tmpstr,"%i",SaveCRC);
	WritePrivateProfileString("USB CopyNES","SaveCRC",tmpstr,Config);
	sprintf(tmpstr,"%i",SaveFiles);
	WritePrivateProfileString("USB CopyNES","SaveFiles",tmpstr,Config);
	sprintf(tmpstr,"%i",MakeUnif);
	WritePrivateProfileString("USB CopyNES","MakeUnif",tmpstr,Config);
 	WritePrivateProfileString("USB CopyNES","PRGPath",_relpath(strcpy(tmpdir,Path_PRG),Path_MAIN),Config);
	WritePrivateProfileString("USB CopyNES","CHRPath",_relpath(strcpy(tmpdir,Path_CHR),Path_MAIN),Config);
	WritePrivateProfileString("USB CopyNES","WRAMPath",_relpath(strcpy(tmpdir,Path_WRAM),Path_MAIN),Config);
	WritePrivateProfileString("USB CopyNES","NESPath",_relpath(strcpy(tmpdir,Path_NES),Path_MAIN),Config);
	WritePrivateProfileString("USB CopyNES","CRCPath",_relpath(strcpy(tmpdir,Path_CRC),Path_MAIN),Config);
	WritePrivateProfileString("USB CopyNES","NSFPath",_relpath(strcpy(tmpdir,Path_NSF),Path_MAIN),Config);
	WritePrivateProfileString("USB CopyNES","PluginPath",_relpath(strcpy(tmpdir,Path_PLUG),Path_MAIN),Config);
	sprintf(tmpstr,"%i",ParPort);
	WritePrivateProfileString("USB CopyNES","ParPort",tmpstr,Config);
	if(ParPort == -1)	//Force consistent settings when in USB mode.
	{
		ParAddr = 0;
		ParECP = 0;
	}
	sprintf(tmpstr,"%X",ParAddr);
	WritePrivateProfileString("USB CopyNES","ParAddr",tmpstr,Config);
	sprintf(tmpstr,"%X",ParECP);
	WritePrivateProfileString("USB CopyNES","ParECP",tmpstr,Config);
}

int	FindVersion (void)
{
	BYTE i;
    OpenStatus(topHWnd);
	StatusText("Querying CopyNES BIOS version...");
	if (!WriteByteEx(0xA2,3,FALSE))
	{
		StatusText("Failed to send version request!");
		StatusText("Make sure your CopyNES is plugged in and turned on!");
		StatusOK();
		return 0;	// write failed, device not present
	}
	if (ParPort != -1)	//After sending the byte, if this is first poweron of copynes in a while, the command may not have
		InitPort();		//actually been received where it should have been. Reset the copynes, then resend the command.
	ResetNES(RESET_COPYMODE);
	if (!WriteByteEx(0xA2,3,FALSE))
	{
		StatusText("Failed to send version request!");
		StatusText("Make sure your CopyNES is plugged in and turned on!");
		StatusOK();
		return 0;	// write failed, device not present
	}
	StatusText("Waiting for reply...");
	if (!ReadByteEx(&i,3,FALSE))
	{
		if (ParPort == -1)
		{
			StatusText("Version reply not received!");
			StatusText("Make sure your CopyNES is plugged in and turned on!");
			StatusOK();
			return 0;	// write failed, device not present
		}
		else
		{
			StatusText("Version reply not received! Assuming version 1 BIOS.");
			Sleep(SLEEP_LONG);
			CloseStatus();
			InitPort();
			ResetNES(RESET_COPYMODE);
			return 1;
		}
	}
	if ((i == 0xA2) && (ParPort != -1))
	{
		StatusText("Your parallel port does not support bidirectional communication!");
		StatusText("Please correct your BIOS settings and try again.");
		StatusOK();
		return 0;	// read failed, device not present
	}
	StatusText("CopyNES identified as version %i.",i);
	Sleep(SLEEP_LONG);
	CloseStatus();
	// technically, these shouldn't be needed
	if (ParPort != -1)
		InitPort();
	ResetNES(RESET_COPYMODE);
	return i;
}

PCategory *Plugins = NULL;
int numcats = -1;

static	void	trim (char *str)
{
	int i;
	for (i = strlen(str) - 1; i >= 0; i--)
	{
		if (str[i] == ' ')
			str[i] = 0;
		else	break;
	}
}

BOOL IsValidPlugin(char *name)
{
	FILE* PLUGIN;
	int size;
	char filename[MAX_PATH];
	strcpy(filename,Path_PLUG);
	strcat(filename,name);
	if ((PLUGIN = fopen(filename,"rb")) == NULL)
		return FALSE;
	fseek(PLUGIN,0,SEEK_END);
	size=ftell(PLUGIN);
	fclose(PLUGIN);
	return size>=1152;
}


int usedcategoryleft = 0;
BOOL MakeCategory(char *description, int type)
{
	numcats++;
	if(numcats)
		Plugins = (PCategory*)realloc(Plugins, (numcats+1) * sizeof(PCategory));	// allocate another slot
	else
		Plugins = (PCategory*)malloc(sizeof(PCategory));
	
	Plugins[numcats] = (PCategory)malloc(sizeof(TCategory));
	Plugins[numcats]->list = (PPlugin*)malloc(0);
	Plugins[numcats]->listlen = 0;
	Plugins[numcats]->type = type;
	Plugins[numcats]->desc = strdup(description);
	
	return TRUE;
}



BOOL MakePlugin(int category, char *name, char *file, int number, char *description)
{
	TPlugin *plugin;

	plugin = (TPlugin*)malloc(sizeof(TPlugin));
	if(plugin == NULL)
		return FALSE;
	
	if(number != 9998)
	{
		if (!IsValidPlugin(file))
		{
			free(plugin);
			return FALSE;
		}
		else
		{
			plugin->file = strdup(file);
		}
	}
	else
		plugin->file = strdup(file);

	plugin->name = strdup(name);
	plugin->num = number;
	plugin->desc = strdup(description);

	Plugins[category]->list = (PPlugin*)realloc(Plugins[category]->list, (Plugins[category]->listlen+1) * sizeof(TPlugin));
	Plugins[category]->list[Plugins[category]->listlen] = plugin;
	Plugins[category]->listlen++;

	return TRUE;
}

BOOL	Startup	(void)
{
	char mapfile[MAX_PATH];
	FILE *PlugList;
	char *Data, *C1, *C2, *C3, *C4;
	int col0, col1, col2, col3, col4;


	InitCRC();
	GetProgPath();
	GetConfig();

	sprintf(mapfile,"%s%s",Path_MAIN, "mappers.dat");
	PlugList = fopen(mapfile, "rt");
	if (PlugList == NULL)
	{
		MessageBox(topHWnd,"Unable to open mappers.dat plugin list!", "USB CopyNES", MB_OK | MB_ICONERROR);
		return FALSE;
	}
	// step 1 - Read the column information
	fscanf(PlugList,"%i %i %i %i %i\n", &col0, &col1, &col2, &col3, &col4);
	col0--; col1--; col2--; col3--; col4--;
	C1 = (char*)malloc(col1 - col0 + 1);	C1[col1 - col0] = 0;
	C2 = (char*)malloc(col2 - col1 + 1);	C2[col2 - col1] = 0;
	C3 = (char*)malloc(col3 - col2 + 1);	C3[col3 - col2] = 0;
	C4 = (char*)malloc(col4 - col3 + 1);	C4[col4 - col3] = 0;
	Data = (char*)malloc(col4);

	// step 2 - read in the list
	while (!feof(PlugList))
	{
		fscanf(PlugList,"%[^\n]\n",Data);
		memcpy(C1,Data + col0, col1 - col0);
		memcpy(C2,Data + col1, col2 - col1);
		memcpy(C3,Data + col2, col3 - col2);
		memcpy(C4,Data + col3, col4 - col3);
		trim(C1);
		trim(C2);
		trim(C3);
		trim(C4);
		if(!strncmp(C1,"****",4))
			continue;	//Comment line, the rest of it should be ignored.
		if (!strcmp(C1,"*"))
		{
			if (!strcmp(C4,"end"))
				break;
			MakeCategory(C4,atoi(C3));
		}
		else
		{
			MakePlugin(numcats,C1,C2,atoi(C3),C4);
		}
	}

	fclose(PlugList);
	free(C1);
	free(C2);
	free(C3);
	free(C4);
	free(Data);

	if (!OpenPort(ParPort, ParAddr, ParECP))
	{
		HWVer = 0;
		return TRUE;
	}
	if (ParPort != -1)
		InitPort();
	ResetNES(RESET_COPYMODE);
	Sleep(SLEEP_LONG);
	ResetNES(RESET_COPYMODE);
	HWVer = FindVersion();
	return TRUE;
}

void	Shutdown (void)
{
	int i, j;
	
	if (Plugins)
	{
		for (i = 0; i <= numcats; i++)
		{
			for (j = 0; j < Plugins[i]->listlen; j++)
			{
				if(Plugins[i]->list[j]->desc) free(Plugins[i]->list[j]->desc);
				if(Plugins[i]->list[j]->file) free(Plugins[i]->list[j]->file);
				if(Plugins[i]->list[j]->name) free(Plugins[i]->list[j]->name);
				if(Plugins[i]->list[j]) free(Plugins[i]->list[j]);
			}
			free(Plugins[i]->desc);
			free(Plugins[i]);
		}
		free(Plugins);
	}
	ResetNES(RESET_PLAYMODE);
	ClosePort();
}
