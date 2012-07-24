#include "StdAfx.h"

static	UINT32	CRCtable[256];
void	InitCRC (void)
{
	const UINT32 poly = 0xEDB88320;
	unsigned int i, j, n, carry;
	for (i = 0; i < 256; i++)
	{
		n = i;
		for (j = 0; j < 8; j++)
		{
			carry = (n & 1);
			n >>= 1;
			if (carry)
				n ^= poly;
		}
		CRCtable[i] = n;
	}
}
UINT32	GetCRC (FILE *File)
{
	int offset = ftell(File);
	UINT32 CRC = 0xFFFFFFFF;
	fseek(File,0,SEEK_SET);
	while (1)
	{
		unsigned char ec;
		if (!fread(&ec,1,1,File))
			break;
		CRC = (CRC >> 8) ^ (CRCtable[(CRC ^ ec) & 0xFF]);
	}
	fseek(File,offset,SEEK_SET);
	CRC ^= 0xFFFFFFFF;
	return CRC;
}
