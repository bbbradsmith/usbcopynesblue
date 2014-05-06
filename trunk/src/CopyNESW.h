#ifndef COPYNESW_H
#define COPYNESW_H

#ifdef __cplusplus
extern "C" {
#endif
extern	HINSTANCE hInst;
extern	HWND	topHWnd;

/* Plugins */
typedef	struct	Plugin
{
	char *name;
	char *file;
	int num;
	char *desc;
	int load_nsf;
}	TPlugin, *PPlugin;

typedef	struct	Category
{
	PPlugin *list;
	int listlen;
	int type;
	char *desc;
}	TCategory, *PCategory;
extern	PCategory *Plugins;
extern int numcats;

/* Misc Dialogs */
extern	HWND	DlgStatus;
void	CloseStatus (void);
void	OpenStatus (HWND hWnd);
void	__cdecl	StatusText (char *text, ...);
void	StatusPercent (int percent);
void	StatusButton (void);
void	StatusButtonAsync (BOOL);
BOOL	StatusButtonPressed (void);
void	StatusOK (void);
char	*PromptTitle;
char	PromptResult[1024];
BOOL	Prompt (HWND hWnd);
BOOL	PromptLong (HWND hWnd);
BOOL	PromptFile (HWND hWnd, char *Filter, char *FilePath, char *FileName, char *InitDir, char *Title, char *DefExt, BOOL Save);
PPlugin	PromptPlugin (int Type);
#define	PLUG_STD	0
#define	PLUG_WRAM	1
#define	PLUG_UTIL	2
#define	PLUG_UPLOAD	3
#define PLUG_NSF	4

/* CRC32 */
void	InitCRC	(void);
UINT32	GetCRC	(FILE *File);

/* Config */
extern	int	HWVer;
extern	int	ParPort, ParAddr, ParECP;
extern	BOOL	SaveCRC, SaveFiles, MakeUnif;
extern	char	Path_MAIN[MAX_PATH], Path_PRG[MAX_PATH], Path_CHR[MAX_PATH], Path_WRAM[MAX_PATH],
	Path_NES[MAX_PATH], Path_CRC[MAX_PATH], Path_NSF[MAX_PATH], Path_PLUG[MAX_PATH];
char *	addSlash (char *path);
void	WriteConfig (void);


/* I/O routines */
#define	RESET_COPYMODE	0
#define	RESET_PLAYMODE	1
#define	RESET_ALTPORT	2
#define	RESET_NORESET	4
extern	char	ROMstring[256];


BOOL	OpenPort	(int, int, int);
void InitPort	(void);
void	ClosePort (void);
void	ResetNES	(int);
BOOL	ReadByte	(BYTE *);
BOOL	WriteByte	(BYTE);
BOOL WriteBlock (BYTE*, int);
BOOL	ReadByteSilent	(BYTE *);
BOOL	WriteByteSilent	(BYTE);
BOOL	ReadByteEx (BYTE *, int, BOOL);
BOOL	WriteByteEx (BYTE, int, BOOL);
BOOL    ReadByteReady (void);
BOOL	WriteCommand	(BYTE,BYTE,BYTE,BYTE,BYTE);
BOOL	LoadPlugin	(char *);
BOOL	RunCode		(void);
static int SystemVersion(void);
static BOOL	OpenUSB (void);
static	void	CloseUSB (void);
unsigned char	prData (void);
void	pwData (unsigned char);
unsigned char	prStatus (void);
void	pwControl (unsigned char);
unsigned char	prECP (void);
void	pwECP (unsigned char);


/* Miscellaneous functions */
#define	SLEEP_SHORT	100
#define	SLEEP_LONG	1000
char	*strjoin3	(char *out, const char *in1, const char *in2, const char *in3);
void	WriteUNIF	(char *,char *,int,int,int,int);
void	WriteNES	(char *,int,int,int,int,int,int,int,int,int);
void	DoEvents	();

#define	MSGBOX_TITLE	"USB CopyNES - " CMD_NAME

#ifdef __cplusplus
}
#endif

#endif /* COPYNESW_H */
