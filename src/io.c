#include "StdAfx.h"
#include <time.h>

static FT_HANDLE ftHandleA;  //DATA BUS
static FT_HANDLE ftHandleB;  //CONTROL BUS
static FT_STATUS ftStatus;   //STATUS

char	ROMstring[256];
char    RxBuffer[64];
char    TxBuffer[64];


//CHANGE ME add ReadBlock



BOOL	ReadByteEx (BYTE *data, BOOL warn)   //read byte from copynes, return good/bad flag
{  
  DWORD BytesReceived = 0;
  
  FT_SetTimeouts(ftHandleA,10000,0);
  ftStatus = FT_Read(ftHandleA,RxBuffer,1,&BytesReceived);
  if (ftStatus == FT_OK) 
  { 
    if (BytesReceived == 1)
    { 
      // FT_Read OK 
      //MessageBox(topHWnd, "Read Success", "ReadByteEx", MB_OK | MB_ICONERROR);
      *data = RxBuffer[0];
      return TRUE;
    } 
    else 
    { 
      // FT_Read Timeout 
      if (warn)
        MessageBox(topHWnd, "USB Error: Read Timeout", "ReadByteEx", MB_OK | MB_ICONERROR);
      return FALSE;  
    } 
  } 
  else 
  { 
    // FT_Read Failed 
    //if (warn)
      MessageBox(topHWnd, "USB Error: Read Failed", "ReadByteEx", MB_OK | MB_ICONERROR);
    return FALSE;  
  } 
}




BOOL	WriteByteEx (BYTE data, BOOL warn)  //write byte to copynes, return good/bad flag
{
  DWORD BytesWritten = 0;

  FT_SetTimeouts(ftHandleA,10000,0);
  
  TxBuffer[0] = data;
  
  ftStatus = FT_Write(ftHandleA,TxBuffer,1,&BytesWritten);
  if (ftStatus == FT_OK)
  { 
    if (BytesWritten == 1) 
    { 
      //MessageBox(topHWnd, "Write Success!", "WriteByte", MB_OK | MB_ICONERROR);
      // FT_Read OK
      return TRUE;
    } 
    else 
    { 
      // FT_Write Timeout 
      if (warn)
        MessageBox(topHWnd, "USB Error: Write Timeout", "WriteByteEx", MB_OK | MB_ICONERROR);
      return FALSE;  
    } 
  } 
  else 
  { 
    // FT_Write Failed 
    //if (warn)
      	StatusText("FT STATUS = %i", ftStatus);
             MessageBox(topHWnd, "USB Error: Write Failed", "WriteByteEx", MB_OK | MB_ICONERROR);

    return FALSE;  
  } 
}








BOOL WriteBlock (char* blockdata, int size)
{
  DWORD BytesWritten = 0;

  FT_SetTimeouts(ftHandleA,10000,0);
  
  ftStatus = FT_Write(ftHandleA, blockdata, size, &BytesWritten);
  if (ftStatus == FT_OK)
  { 
    if (BytesWritten == size) 
    { 
      // FT_Read OK
      //MessageBox(topHWnd, "Write Success!", "WriteByte", MB_OK | MB_ICONERROR);
      return TRUE;
    } 
    else 
    { 
      // FT_Write Timeout 
      MessageBox(topHWnd, "USB Error: Write Timeout", "WriteBlock", MB_OK | MB_ICONERROR);
      return FALSE;  
    } 
  } 
  else 
  { 
    // FT_Write Failed 
          	StatusText("FT STATUS = %i", ftStatus);
    MessageBox(topHWnd, "USB Error: Write Failed", "WriteBlock", MB_OK | MB_ICONERROR);
    return FALSE;  
  }       
}


BOOL	ReadByte (BYTE *data)
{
	return ReadByteEx(data, TRUE);
}
BOOL	WriteByte (BYTE data)
{
	return WriteByteEx(data, TRUE);
}

BOOL	ReadByteSilent (BYTE *data)
{
	return ReadByteEx(data, FALSE);
}
BOOL	WriteByteSilent (BYTE data)
{
	return WriteByteEx(data, FALSE);
}



BOOL ReadByteReady (void)    //check if byte is waiting in queue
{
  DWORD EventDWord = 0;
  DWORD RxBytes = 0;
  DWORD TxBytes = 0;
  

  FT_GetStatus(ftHandleA,&RxBytes,&TxBytes,&EventDWord);
  if (RxBytes > 0)
    return TRUE;
  else
    return FALSE;
}





BOOL	OpenPort (void)
{
  ftStatus = FT_OpenEx("USB CopyNES A",FT_OPEN_BY_DESCRIPTION,&ftHandleA);   //open data bus
  if (ftStatus == FT_OK) 
  { 
    // success - device open 
    //MessageBox(topHWnd, "OpenEX1 passed!", "OpenPort", MB_OK | MB_ICONERROR); 
  } 
  else 
  { 
    // failure - one or both of the devices has not been opened 
    MessageBox(topHWnd, "USB Error: Open USB CopyNES A Failed!", "OpenPort", MB_OK | MB_ICONERROR);
    return FALSE;  
  } 

  ftStatus = FT_OpenEx("USB CopyNES B",FT_OPEN_BY_DESCRIPTION,&ftHandleB);   //open control bus
  if (ftStatus == FT_OK) 
  { 
    // success - device open 
    //MessageBox(topHWnd, "OpenEX2 passed", "OpenPort", MB_OK | MB_ICONERROR);   
  } 
  else 
  { 
    MessageBox(topHWnd, "USB Error: Open USB CopyNES B Failed!", "OpenPort", MB_OK | MB_ICONERROR); 
    // failure - one or both of the devices has not been opened 
    return FALSE;
  } 
  return TRUE;

}




void	InitPort (void)
{
  DWORD modemWord = 0;

  ftStatus = FT_GetModemStatus (ftHandleB, &modemWord);
  if (ftStatus == FT_OK) 
  { 
    // success - status received
    //MessageBox(topHWnd, "GetModemStatus passed", "InitPort", MB_OK | MB_ICONERROR); 
    if (modemWord & 0x80)
    {
      MessageBox(topHWnd, "NES is OFF - turn on then hit OK", "InitPort", MB_OK | MB_ICONERROR);            
    }
    else
    {
     //MessageBox(topHWnd, "NES is ON", "InitPort", MB_OK | MB_ICONERROR);            
    }    
  } 
  else 
  { 
    MessageBox(topHWnd, "USB Error: Get Power Status Failed!", "InitPort", MB_OK | MB_ICONERROR); 
    // failure 
    return;
  } 
  
  
     
  //flush receive/transmit buffers
  ftStatus = FT_Purge (ftHandleA, FT_PURGE_RX | FT_PURGE_TX);
  if (ftStatus == FT_OK) 
  { 
    // success - buffers empty 
    //MessageBox(topHWnd, "Purge A passed", "InitPort", MB_OK | MB_ICONERROR); 
  } 
  else 
  { 
    MessageBox(topHWnd, "USB Error: Purge A Failed!", "InitPort", MB_OK | MB_ICONERROR); 
    // failure 
    return;
  } 
  ftStatus = FT_Purge (ftHandleB, FT_PURGE_RX | FT_PURGE_TX);
  if (ftStatus == FT_OK) 
  { 
    // success - buffers empty 
    //MessageBox(topHWnd, "Purge B passed", "InitPort", MB_OK | MB_ICONERROR); 
  } 
  else 
  { 
    MessageBox(topHWnd, "USB Error: Purge B Failed!", "InitPort", MB_OK | MB_ICONERROR); 
    // failure 
  }   
}



void	ClosePort (void)
{
  FT_Close(ftHandleA);
  FT_Close(ftHandleB);
}




void	ResetNES (int rtype)
{
      
	if (rtype & RESET_PLAYMODE)
    {
      //clr /RTS=1
      ftStatus = FT_ClrRts(ftHandleB); 
      if (ftStatus == FT_OK) 
      { 
        // FT_ClrRts OK 
      } 
      else 
      { 
        // FT_ClrRts failed
        MessageBox(topHWnd, "USB Error: ClrRts Failed!", "ResetNES", MB_OK | MB_ICONERROR); 
        return;
      } 
    }
	else
    {	
      //set /RTS=0
      ftStatus = FT_SetRts(ftHandleB); 
      
      if (ftStatus == FT_OK) 
      { 
          // FT_SetRts OK 
      } 
      else 
      { 
        MessageBox(topHWnd, "USB Error: SetRts Failed!", "ResetNES", MB_OK | MB_ICONERROR);
        return; 
        //FT_SetRts failed
      } 
    }
  
  
  
  
	if (!(rtype & RESET_NORESET))
	{
	  // pull /RESET low    clear D2

      //set /dtr=0
      ftStatus = FT_ClrDtr(ftHandleB); 
      if (ftStatus == FT_OK)
      { 
        // OK 
      } 
      else 
      { 
        // failed 
        MessageBox(topHWnd, "USB Error: ClrDtr Failed!", "ResetNES", MB_OK | MB_ICONERROR); 
        return;    
      }     
      Sleep(SLEEP_SHORT);
    }

                                                                    

  
	// pull /RESET high       set D2
    //clr /dtr=1
    ftStatus = FT_SetDtr(ftHandleB); 
    if (ftStatus == FT_OK) 
    { 
      // OK
    }
    else
    { 
      MessageBox(topHWnd, "USB Error: SetDtr Failed!", "ResetNES", MB_OK | MB_ICONERROR); 
      return;
    } 

	Sleep(SLEEP_SHORT);
	
	InitPort();
	
	Sleep(SLEEP_SHORT);	
	
}








BOOL	WriteCommand (BYTE a, BYTE b, BYTE c, BYTE d, BYTE e)
{
	if (WriteByteSilent(a) && WriteByteSilent(b) && WriteByteSilent(c) && WriteByteSilent(d) && WriteByteSilent(e))
		return TRUE;
	else
	{
		MessageBox(topHWnd, "USB Error: Timeout on data transfer!", "WriteCommand", MB_OK | MB_ICONERROR);
		return FALSE;
	}
}



BOOL	LoadPlugin (char *plugin)
{
	int w;
	char filename[MAX_PATH];
	FILE *PLUGIN;
	char *filedata;
	BOOL status;
	
	strcpy(filename,Path_PLUG);
	strcat(filename,plugin);
	
	if ((PLUGIN = fopen(filename,"rb")) == NULL)
	{
		MessageBox(topHWnd,"Failed to open plugin file!","LoadPlugin",MB_OK | MB_ICONERROR);
		return FALSE;
	}
	if (!WriteCommand(0x4B,0x00,0x04,0x04,0xB4))	// write to CPU space
	{	// failed to load plugin
		fclose(PLUGIN);
		return FALSE;
	}
	fseek(PLUGIN,128,SEEK_SET);
	filedata = malloc(1024);
	fread((void*)filedata, 1024, 1, PLUGIN);
	
	status = WriteBlock(filedata, 1024);
	free(filedata);
  
  if (!status)
  {
		fclose(PLUGIN);
		return FALSE;
  }

	for (w = 0; !feof(PLUGIN); w++)
		fread(&ROMstring[w],1,1,PLUGIN);
	ROMstring[w] = 0;
	fclose(PLUGIN);
	StatusPercent(0);
	Sleep(SLEEP_SHORT);
	return TRUE;
}



BOOL	RunCode (void)
{
	return WriteCommand(0x7E,0x00,0x04,0x00,0xE7);
}
