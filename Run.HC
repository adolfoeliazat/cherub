CTask *cherub;
U8 RunCmd[1024];
U8 RomList[8192];

I64 pos=0;
CDirEntry *rom_f;
CDirEntry *roms=FilesFind("Roms/*.gb");

rom_f=roms;
while (rom_f)
{
  StrCpy(RomList+pos,rom_f->name);
  pos += StrLen(rom_f->name) + 1;
  rom_f=rom_f->next;
};



I64 rom_i = PopUpPickLst(RomList);

"%d\n",rom_i;

I64 incr=0;
rom_f=roms;

if (rom_i>-1)
{
  while (incr<rom_i)
  {
    rom_f=rom_f->next;
    incr++;
  };
  StrPrint(RunCmd,"Cd(\"%s\");\n#include \"Load\";\nRun(\"%s\");\n",DirCur,rom_f->full_name);
  cherub=User(RunCmd);
  Sleep(100);
  WinFocus(Fs);
  Sleep(100);
  WinFocus(cherub);
};

DirEntryDel(roms);
rom_f=NULL;

