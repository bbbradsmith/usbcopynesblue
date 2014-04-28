#include "StdAfx.h"
#define	CMD_NAME	"Split UNIF"

BOOL	CMD_SPLITUNIF (void)
{
	FILE *UNIF;
	char filename[MAX_PATH], basename[MAX_PATH];
	BYTE buf[1024];
	DWORD len;
	int i;
	
	PromptFile(topHWnd,"UNIF Files (*.UNIF,*.UNF)\0*.unif,*.unf\0\0",filename,basename,NULL,"Select a ROM","unif",FALSE);
	if (!basename[0])
		return FALSE;
	i = strlen(basename);
	while (basename[i] != '.')
		i--;
	basename[i] = 0;	// drop the extension
	
	UNIF = fopen(filename,"rb");

	fread(buf,1,4,UNIF);
	if (memcmp("UNIF",buf,4))
	{
		fclose(UNIF);
		MessageBox(topHWnd,"This is not a UNIF ROM image!",MSGBOX_TITLE,MB_OK | MB_ICONERROR);
		return FALSE;
	}
	fseek(UNIF,28,SEEK_CUR);

	fread(buf,1,4,UNIF);
	fread(&len,4,1,UNIF);
	while (!feof(UNIF))
	{
		char outname[MAX_PATH];
		FILE *OUTPUT;
		if (!memcmp(buf,"MIRR",4))
		{
			const char *mir[6] = {"Horizontal","Vertical","Single-screen L","Single-screen H","Four-screen","Mapper-controlled"};
			char msg[48];
			BYTE a;
			fread(&a,1,1,UNIF);
			sprintf(msg,"Mirroring type: %s",mir[a]);
			MessageBox(topHWnd,msg,MSGBOX_TITLE,MB_OK | MB_ICONINFORMATION);
			fseek(UNIF,len-1,SEEK_CUR);
		}
		else if (!memcmp(buf,"DINF",4))
		{
			char msg[256];
			char info[205];
			fread(info,1,204,UNIF);
			info[204] = 0;
			sprintf(msg,"Dumped by %s on %i/%i/%i using %s",
				info,
				info[100] | info[101] << 8,
				info[102],
				info[103],
				info + 104);
			MessageBox(topHWnd,msg,MSGBOX_TITLE,MB_OK | MB_ICONINFORMATION);
			fseek(UNIF,len-204,SEEK_CUR);
		}
		else if (!memcmp(buf,"MAPR",4))
		{
			char *msg = malloc(len + 16);
			char *board = malloc(len);
			fread(board,1,len,UNIF);
			sprintf(msg,"Board name: %s",board);
			free(board);
			MessageBox(topHWnd,msg,MSGBOX_TITLE,MB_OK | MB_ICONINFORMATION);
			free(msg);
		}
		else if (!memcmp(buf,"PRG",3))
		{
			sprintf(outname,"%s%s.pr%c",Path_PRG,basename,buf[3]);
			OUTPUT = fopen(outname,"wb");
			for (i = 0; i < (signed)len; i++)
			{
				BYTE a;
				fread(&a,1,1,UNIF);
				fwrite(&a,1,1,OUTPUT);
			}
			fclose(OUTPUT);
		}
		else if (!memcmp(buf,"CHR",3))
		{
			sprintf(outname,"%s%s.pr%c",Path_CHR,basename,buf[3]);
			OUTPUT = fopen(outname,"wb");
			for (i = 0; i < (signed)len; i++)
			{
				BYTE a;
				fread(&a,1,1,UNIF);
				fwrite(&a,1,1,OUTPUT);
			}
			fclose(OUTPUT);
		}
		else
		{
			// dunno, skip to end of block
			fseek(UNIF,len,SEEK_CUR);
		}
		fread(buf,1,4,UNIF);
		fread(&len,4,1,UNIF);
	}
	fclose(UNIF);
	MessageBox(topHWnd,"Done!",MSGBOX_TITLE,MB_OK);
	return TRUE;
}
