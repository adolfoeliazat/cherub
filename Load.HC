StrCpy(Fs->task_name,"");
StrCpy(Fs->task_title,"");
// Settings
#include "Settings";
I64 keyCtr=0;
I64 sc=0;
I64 ROMSize=0;
I64 bgp3,bgp2,bgp1,bgp0;
I64 obp03,obp02,obp01,obp00;
I64 obp13,obp12,obp11,obp10;
I64 jp_state[8];

U0 SetPal(U8 p, I64 *c0, I64 *c1, I64 *c2, I64 *c3)
{
  I64 col[4];
  I64 colctr=0;
  while (colctr<4)
  {
    if((p>>((colctr*2)+1))&1)
    {
      if((p>>((colctr*2)))&1){col[colctr]=0;}else{col[colctr]=8;};
    } else {
      if((p>>((colctr*2)))&1){col[colctr]=7;}else{col[colctr]=15;};
    };
    colctr++;
  };
  *c0=col[0];
  *c1=col[1];
  *c2=col[2];
  *c3=col[3];  
};

U8 *ROM;

//Actual scan line...
I64 actualScanLine = 0;
//Is the emulated LCD controller on?
Bool LCDisOn = FALSE;
//Should we trigger an interrupt if LY==LYC?
Bool LYCMatchTriggerSTAT = FALSE;
//The scan line mode (for lines 1-144 it's 2-3-0, for 145-154 it's 1)
I64 modeSTAT = 0;
//Should we trigger an interrupt if in mode 0?
Bool mode0TriggerSTAT = FALSE;
//Should we trigger an interrupt if in mode 1?
Bool mode1TriggerSTAT = FALSE;
//Should we trigger an interrupt if in mode 2?
Bool mode2TriggerSTAT = FALSE;
//Tracker for STAT triggering.
I64 STATTracker = 0;

I64 arrayCtr=0;
// Used by opcode switch statements
I64 opcode;
I64 cb_opcode;
I64 temp_var;
I64 n2;
I64 dirtySum;
I64 carry_flag;
I64 H;
I64 L;
I64 bitShift;
I64 testbit;
I64 interrupts;
I64 tempValue;
I64 temp_pc;
I64 newFCarry;
I64 signedByte;
I64 temp_value;
// Accumulator (default is GB mode)
I64 registerA = 0x01;
// bit 7 - Zero
Bool FZero = TRUE;
// bit 6 - Sub
Bool FSubtract = FALSE;
// bit 5 - Half Carry
Bool FHalfCarry = TRUE;
// bit 4 - Carry
Bool FCarry = TRUE;
// Register B
I64 registerB = 0x00;
// Register C
I64 registerC = 0x13;
// Register D
I64 registerD = 0x00;
// Register E
I64 registerE = 0xD8;
// Registers H and L
I64 registersHL = 0x014D;
// Stack Pointer
I64 stackPointer = 0xFFFE;
// Program Counter
I64 programCounter = 0x0100;
//Has the CPU been suspended until the next interrupt?
Bool halt = FALSE;
//Did we trip the DMG Halt bug?
Bool skipPCIncrement = FALSE;
//Has the emulation been paused or a frame has ended?
I64 stopEmulator = 3;
//Are interrupts enabled?
Bool IME = TRUE;
//HDMA Transfer Flag - GBC only
Bool hdmaRunning = FALSE;
//The number of clock cycles emulated.
I64 CPUTicks = 0;
//GBC Speed Multiplier
I64 multiplier = 1;
//
//Main RAM, MBC RAM, VRAM, etc.
//
//Main Core Memory
I64 memory[0x10000];

I64 mc_ctr;
mc_ctr = 0x8000;
while(mc_ctr<0xC000) { memory[mc_ctr]=0; mc_ctr++; };

mc_ctr = 0xFF00;
while(mc_ctr<0xFFFF) { memory[mc_ctr]=0; mc_ctr++; };

//Switchable RAM (Used by games for more RAM) for the main memory range 0xA000 - 0xC000.
I64 MBCRam[0x10000];
//MBC1 Type (4/32, 16/8)
Bool MBC1Mode = FALSE;
//MBC RAM Access Control.
Bool MBCRAMBanksEnabled = FALSE;
//MBC Currently Indexed RAM Bank
I64 currMBCRAMBank = 0;
//MBC Position Adder;
I64 currMBCRAMBankPosition = -0xA000;
//Used to map the RAM banks to maximum size the MBC used can do.
I64 RAMBanks[5] = {0, 1, 2, 4, 16};
//Offset of the ROM bank switching.
I64 ROMBank1offs = 0;
//The parsed current ROM bank selection.
I64 currentROMBank = 0;
//Cartridge Type
I64 cartridgeType = 0;
//Name of the game
//name = '';
//Game code (Suffix for older games)
//gameCode = '';
//A boolean to see if this was loaded in as a save state.
Bool fromSaveState = FALSE;
//When loaded in as a save state, this will not be empty.
//savedStateFileName = '';
//lcdControllerler object
//lcdController = null;
Bool gfxWindowY = FALSE;
Bool gfxWindowDisplay = FALSE;
Bool gfxSpriteShow = FALSE;
Bool gfxSpriteDouble = FALSE;
Bool gfxBackgroundY = FALSE;
Bool gfxBackgroundX = FALSE;
Bool TIMAEnabled = FALSE;
//Joypad State (two four-bit states actually)
I64 JoyPad = 0xFF;
//
//RTC:
//
Bool RTCisLatched = TRUE;
I64 latchedSeconds = 0;
I64 latchedMinutes = 0;
I64 latchedHours = 0;
I64 latchedLDays = 0;
I64 latchedHDays = 0;
I64 RTCSeconds = 0;
I64 RTCMinutes = 0;
I64 RTCHours = 0;
I64 RTCDays = 0;
Bool RTCDayOverFlow = FALSE;
Bool RTCHALT = FALSE;
//
//Timing Variables
//
//Used to sample the audio system every x CPU instructions.
I64 audioTicks = 0;
//Times for how many instructions to execute before ending the loop.
I64 emulatorTicks = 0;
// DIV Ticks Counter (Invisible lower 8-bit)
I64 DIVTicks = 14;
// ScanLine Counter
I64 LCDTicks = 15;
// Timer Ticks Count
I64 timerTicks = 0;
// Timer Max Ticks
I64 TACClocker = 256;
//Are the interrupts on queue to be enabled?
I64 untilEnable = 0;
//The last time we iterated the main loop.
I64 lastIteration = 0;
//
//ROM Cartridge Components:
//

Bool cBATT = FALSE;
//Does the cartridge use MBC1?
Bool cMBC1 = FALSE;
//Does the cartridge use MBC2?
Bool cMBC2 = FALSE;
//Does the cartridge use MBC3?
Bool cMBC3 = FALSE;
//Does the cartridge use MBC5?
Bool cMBC5 = FALSE;
//Does the cartridge use save RAM?
Bool cSRAM = FALSE;
Bool cMMMO1 = FALSE;
//Does the cartridge use the RUMBLE addressing (modified MBC5)?
Bool cRUMBLE = FALSE;
Bool cCamera = FALSE;
Bool cTAMA5 = FALSE;
Bool cHuC3 = FALSE;
Bool cHuC1 = FALSE;
// 1 Bank = 16 KBytes = 256 Kbits
I64 ROMBanks[9] = {
    2, 4, 8, 16, 32, 64, 128, 256, 512,
};
//How many RAM banks were actually allocated?
I64 numRAMBanks = 0;
//
//Graphics Variables
//
//To prevent the repeating of drawing a blank screen.
I64 drewBlank = 0;
//GB: 384, GBC: 384 * 2
I64 tileCount = 384;
I64 colorCount = 12;
I64 gbPalette[12] = {0,0,0,0,0,0,0,0,0,0,0,0};
// min "attrib" value where transparency can occur (Default is 4 (GB mode))
I64 transparentCutoff = 4;
Bool bgEnabled = TRUE;
Bool spritePriorityEnabled = TRUE;
// true if there are any images to be invalidated
I64 tileReadState[tileCount];
for(arrayCtr=0;arrayCtr<tileCount;arrayCtr++) { tileReadState[arrayCtr]=0;};

I64 windowSourceLine = 0;
//"Classic" GameBoy palette colors.
I64 colors[4] = {0x80EFFFDE, 0x80ADD794, 0x80529273, 0x80183442};
//Frame skip tracker
I64 frameCount;
//weaveLookup = [];
I64 width = 160;
I64 height = 144;
I64 pixelCount;
I64 rgbCount;
//Pointer to the current palette we're using (Used for palette switches during boot or so it can be done anytime)
I64 palette = 0;
//
//Data
//
#include "Data";
#include "TICKTables";
// Added
I64 cTIMER = 0;
//Helper Functions
I64 t(Bool tf, I64 tv, I64 fv) { if (tf) { return tv; } else { return fv; }; };
I64 usbtsb(I64 ubyte)
{
    //Unsigned byte to signed byte:
    return t((ubyte > 0x7F),((ubyte & 0x7F) - 0x80),ubyte);
}
I64 unsbtub(I64 ubyte)
{
    //Keep an unsigned byte unsigned:
    if (ubyte < 0) {
        ubyte += 0x100;
    }
    return ubyte; //If this function is called, no wrapping requested.
}
I64 nswtuw(I64 uword)
{
    //Keep an unsigned word unsigned:
    if (uword < 0) {
        uword += 0x10000;
    }
    return uword & 0xFFFF; //Wrap also...
}
I64 unswtuw(I64 uword)
{
    //Keep an unsigned word unsigned:
    if (uword < 0) {
        uword += 0x10000;
    }
    return uword; //If this function is called, no wrapping requested.
}

//Memory Reading:
I64 memoryRead(I64 address)
{
    if (address < 0x4000) {
        return ROM[address];
    } else if (address < 0x8000) {
        return ROM[currentROMBank + address];
    } else if (address >= 0x8000 && address < 0xA000) {
        //CPU Side Reading The VRAM (Optimized for classic GameBoy)
        return t((modeSTAT > 2),0xFF,memory[address]);
    } else if (address >= 0xA000 && address < 0xC000) {
        if ((numRAMBanks == 1 / 16 && address < 0xA200) || numRAMBanks >= 1) {
            if (!cMBC3) {
                //memoryReadMBC
                //Switchable RAM
                if (MBCRAMBanksEnabled || overrideMBC) {
                    return MBCRam[address + currMBCRAMBankPosition];
                }
                //cout("Reading from disabled RAM.", 1);
                return 0xFF;
            } else {
                //MBC3 RTC + RAM:
                //memoryReadMBC3
                //Switchable RAM
                if (MBCRAMBanksEnabled || overrideMBC) {
                    switch (currMBCRAMBank) {
                        case 0x00:
                        case 0x01:
                        case 0x02:
                        case 0x03:
                            return MBCRam[address + currMBCRAMBankPosition];
                            break;
                        case 0x08:
                            return latchedSeconds;
                            break;
                        case 0x09:
                            return latchedMinutes;
                            break;
                        case 0x0A:
                            return latchedHours;
                            break;
                        case 0x0B:
                            return latchedLDays;
                            break;
                        case 0x0C:
                            return (t((RTCDayOverFlow),0x80,0) + t((RTCHALT),0x40,0)) + latchedHDays;
                    }
                }
                //cout("Reading from invalid or disabled RAM.", 1);
                return 0xFF;
            }
        } else {
            return 0xFF;
        }
    } else if (address >= 0xC000 && address < 0xE000) {
        return memory[address];
    } else if (address >= 0xE000 && address < 0xFE00) {
            //memoryReadECHONormal
            return memory[address - 0x2000];
    } else if (address < 0xFEA0) {
        //memoryReadOAM
        return t((modeSTAT > 1),0xFF,memory[address]);
    } else if (address >= 0xFF00) {
        switch (address) {
            case 0xFF00:
                return 0xC0 | memory[0xFF00]; //Top nibble returns as set.
                break;
            case 0xFF01:
                return t(((memory[0xFF02] & 0x1) == 0x1),0xFF,memory[0xFF01]);
                break;
            case 0xFF02:
                return 0x7E | memory[0xFF02];
                break;
            case 0xFF07:
                return 0xF8 | memory[0xFF07];
                break;
            case 0xFF0F:
                return 0xE0 | memory[0xFF0F];
                break;
            case 0xFF10:
                return 0x80 | memory[0xFF10];
                break;
            case 0xFF11:
                return 0x3F | memory[0xFF11];
                break;
            case 0xFF14:
                return 0xBF | memory[0xFF14];
                break;
            case 0xFF16:
                return 0x3F | memory[0xFF16];
                break;
            case 0xFF19:
                return 0xBF | memory[0xFF19];
                break;
            case 0xFF1A:
                return 0x7F | memory[0xFF1A];
                break;
            case 0xFF1B:
                return 0xFF;
                break;
            case 0xFF1C:
                return 0x9F | memory[0xFF1C];
                break;
            case 0xFF1E:
                return 0xBF | memory[0xFF1E];
                break;
            case 0xFF20:
                return 0xFF;
                break;
            case 0xFF23:
                return 0xBF | memory[0xFF23];
                break;
            case 0xFF26:
                return 0x70 | memory[0xFF26];
                break;
            case 0xFF30:
            case 0xFF31:
            case 0xFF32:
            case 0xFF33:
            case 0xFF34:
            case 0xFF35:
            case 0xFF36:
            case 0xFF37:
            case 0xFF38:
            case 0xFF39:
            case 0xFF3A:
            case 0xFF3B:
            case 0xFF3C:
            case 0xFF3D:
            case 0xFF3E:
            case 0xFF3F:
                return t(((memory[0xFF26] & 0x4) == 0x4),0xFF,memory[address]);
                break;
            case 0xFF41:
                return 0x80 | memory[0xFF41] | modeSTAT;
                break;
            case 0xFF44:
                return t((LCDisOn),memory[0xFF44],0);
                break;
            case 0xFF4F:
                return 0;
                break;
            default:
                //memoryReadNormal
                return memory[address];
        }
    } else {
        //memoryReadBAD
        return 0xFF;
    }
}

U0 setCurrentMBC1ROMBank()
{
    //Read the cartridge ROM data from RAM memory:
    switch (ROMBank1offs) {
        case 0x00:
        case 0x20:
        case 0x40:
        case 0x60:
            //Bank calls for 0x00, 0x20, 0x40, and 0x60 are really for 0x01, 0x21, 0x41, and 0x61.
            currentROMBank = ROMBank1offs * 0x4000;
            break;
        default:
            currentROMBank = (ROMBank1offs - 1) * 0x4000;
    }
    while (currentROMBank + 0x4000 >= ROMSize) {
        currentROMBank -= ROMSize;
    }
}
U0 setCurrentMBC2AND3ROMBank()
{
    //Read the cartridge ROM data from RAM memory:
    //Only map bank 0 to bank 1 here (MBC2 is like MBC1, but can only do 16 banks, so only the bank 0 quirk appears for MBC2):
    currentROMBank = ToI64(Max(ROMBank1offs - 1, 0)) * 0x4000;
    while (currentROMBank + 0x4000 >= ROMSize) {
        currentROMBank -= ROMSize;
    }
}
U0 setCurrentMBC5ROMBank()
{
    //Read the cartridge ROM data from RAM memory:
    currentROMBank = (ROMBank1offs - 1) * 0x4000;
    while (currentROMBank + 0x4000 >= ROMSize) {
        currentROMBank -= ROMSize;
    }
}

U0 clockUpdate()
{
    //We're tying in the same timer for RTC and frame skipping, since we can and this reduces load.
    if (autoFrameskip || cTIMER) {
        I64 timeElapsed = (HPET/100) - lastIteration; //Get the numnber of milliseconds since this last executed.
        if (cTIMER && !RTCHALT) {
            //Update the MBC3 RTC:
            RTCSeconds += timeElapsed / 1000;
            //System can stutter, so the seconds difference can get large, thus the "while".
            while (RTCSeconds >= 60) {
                RTCSeconds -= 60;
                ++RTCMinutes;
                if (RTCMinutes >= 60) {
                    RTCMinutes -= 60;
                    ++RTCHours;
                    if (RTCHours >= 24) {
                        RTCHours -= 24;
                        ++RTCDays;
                        if (RTCDays >= 512) {
                            RTCDays -= 512;
                            RTCDayOverFlow = TRUE;
                        }
                    }
                }
            }
        }
        if (autoFrameskip) {
            //Auto Frame Skip:
            if (timeElapsed > loopInterval) {
                //Did not finish in time...
                if (frameskipAmount < frameskipMax) {
                    ++frameskipAmount;
                }
            } else if (frameskipAmount > 0) {
                //We finished on time, decrease frame skipping (throttle to somewhere just below full speed)...
                --frameskipAmount;
            }
        }
        lastIteration = (HPET/100);
    }
}

U0 joyPadEvent(I64 key, I64 down)
{
    if (down) {
        JoyPad &= 0xFF ^ (1 << key);
    } else {
        JoyPad |= (1 << key);
    }
    memory[0xFF00] = (memory[0xFF00] & 0x30) + t(((memory[0xFF00] & 0x20) == 0),(JoyPad >> 4),0xF) & t(((memory[0xFF00] & 0x10) == 0),(JoyPad & 0xF),0xF);
}

#include "LCD";

#include "LCDController";

U0 displayShowOff()
{
    if (drewBlank == 0) {
        drewBlank = 2;
    }
}

//Memory Writing:
U0 memoryWrite(I64 address, I64 data)
{ 
    //"%04X:%02X\n",address,data;
    if (address < 0x8000) {
        if (cMBC1) {
            if (address < 0x2000) {
                //MBC RAM Bank Enable/Disable:
                MBCRAMBanksEnabled = ((data & 0x0F) == 0x0A); //If lower nibble is 0x0A, then enable, otherwise disable.
            } else if (address < 0x4000) {
                // MBC1WriteROMBank
                //MBC1 ROM bank switching:
                ROMBank1offs = (ROMBank1offs & 0x60) | (data & 0x1F);
                setCurrentMBC1ROMBank;
            } else if (address < 0x6000) {
                //MBC1WriteRAMBank
                //MBC1 RAM bank switching
                if (MBC1Mode) {
                    //4/32 Mode
                    currMBCRAMBank = data & 0x3;
                    currMBCRAMBankPosition = (currMBCRAMBank << 13) - 0xA000;
                } else {
                    //16/8 Mode
                    ROMBank1offs = ((data & 0x03) << 5) | (ROMBank1offs & 0x1F);
                    setCurrentMBC1ROMBank;
                }
            } else {
                //MBC1WriteType
                //MBC1 mode setting:
                MBC1Mode = ((data & 0x1) == 0x1);
            }
        } else if (cMBC2) {
            if (address < 0x1000) {
                //MBC RAM Bank Enable/Disable:
                MBCRAMBanksEnabled = ((data & 0x0F) == 0x0A); //If lower nibble is 0x0A, then enable, otherwise disable.
            } else if (address >= 0x2100 && address < 0x2200) {
                //MBC2WriteROMBank
                //MBC2 ROM bank switching:
                ROMBank1offs = data & 0x0F;
                setCurrentMBC2AND3ROMBank;
            } else {
                //We might have encountered illegal RAM writing or such, so just do nothing...
            }
        } else if (cMBC3) {
            if (address < 0x2000) {
                //MBC RAM Bank Enable/Disable:
                MBCRAMBanksEnabled = ((data & 0x0F) == 0x0A); //If lower nibble is 0x0A, then enable, otherwise disable.
            } else if (address < 0x4000) {
                //MBC3 ROM bank switching:
                ROMBank1offs = data & 0x7F;
                setCurrentMBC2AND3ROMBank;
            } else if (address < 0x6000) {
                //MBC3WriteRAMBank
                currMBCRAMBank = data;
                if (data < 4) {
                    //MBC3 RAM bank switching
                    currMBCRAMBankPosition = (currMBCRAMBank << 13) -   0xA000;
                }
            } else {
                //MBC3WriteRTCLatch
                if (data == 0) {
                    RTCisLatched = FALSE;
                } else if (!RTCisLatched) {
                    //Copy over the current RTC time for reading.
                    RTCisLatched = TRUE;
                    latchedSeconds = Floor(RTCSeconds);
                    latchedMinutes = RTCMinutes;
                    latchedHours = RTCHours;
                    latchedLDays = (RTCDays & 0xFF);
                    latchedHDays = RTCDays >> 8;
                }
            }
        } else if (cMBC5 || cRUMBLE) {
            if (address < 0x2000) {
                //MBC RAM Bank Enable/Disable:
                MBCRAMBanksEnabled = ((data & 0x0F) == 0x0A); //If lower nibble is 0x0A, then enable, otherwise disable.
            } else if (address < 0x3000) {
                //MBC5WriteROMBankLow
                //MBC5 ROM bank switching:
                ROMBank1offs = (ROMBank1offs & 0x100) | data;
                setCurrentMBC5ROMBank;
            } else if (address < 0x4000) {
                //MBC5WriteROMBankHigh
                //MBC5 ROM bank switching (by least significant bit):
                ROMBank1offs = ((data & 0x01) << 8) | (ROMBank1offs & 0xFF);
                setCurrentMBC5ROMBank;
            } else if (address < 0x6000) {
                if (cRUMBLE) {
                    //MBC5 RAM bank switching
                    //Like MBC5, but bit 3 of the lower nibble is used for rumbling and bit 2 is ignored.
                    currMBCRAMBank = data & 0x3;
                    currMBCRAMBankPosition = (currMBCRAMBank << 13) - 0xA000;
                } else {
                    //MBC5 RAM bank switching
                    currMBCRAMBank = data & 0xF;
                    currMBCRAMBankPosition = (currMBCRAMBank << 13) - 0xA000;
                }
            } else {
                //We might have encountered illegal RAM writing or such, so just do nothing...
            }
        } else if (cHuC3) {
            if (address < 0x2000) {
                //MBC RAM Bank Enable/Disable:
                MBCRAMBanksEnabled = ((data & 0x0F) == 0x0A); //If lower nibble is 0x0A, then enable, otherwise disable.
            } else if (address < 0x4000) {
                //MBC3 ROM bank switching:
                ROMBank1offs = data & 0x7F;
                setCurrentMBC2AND3ROMBank;
            } else if (address < 0x6000) {
                //HuC3WriteRAMBank
                //HuC3 RAM bank switching
                currMBCRAMBank = data & 0x03;
                currMBCRAMBankPosition = (currMBCRAMBank << 13) - 0xA000;
            } else {
                //We might have encountered illegal RAM writing or such, so just do nothing...
            }
        } else {
            //We might have encountered illegal RAM writing or such, so just do nothing...
        }
    } else if (address < 0xA000) {
        // VRAMWrite
        //VRAM cannot be written to during mode 3
        if (modeSTAT < 3) {
            // Bkg Tile data area
            if (address < 0x9800) {
                //I64 tileIndex = ((address - 0x8000) >> 4);
                //if (tileReadState[tileIndex] == 1) {
                //    I64 r = count(tileData) - tileCount + tileIndex;
                //    do {
                //        tileData[r] = null;
                //        r -= tileCount;
                //    } while (r >= 0);
                //    tileReadState[tileIndex] = 0;
                //}
            }
            memory[address] = data;
        }
    } else if (address < 0xC000) {
        if ((numRAMBanks == 1 / 16 && address < 0xA200) || numRAMBanks >= 1) {
            if (!cMBC3) {
                //memoryWriteMBCRAM
                if (MBCRAMBanksEnabled || overrideMBC) {
                    MBCRam[address + currMBCRAMBankPosition] = data;
                }
            } else {
                //MBC3 RTC + RAM:
                //memoryWriteMBC3RAM
                if (MBCRAMBanksEnabled || overrideMBC) {
                    switch (currMBCRAMBank) {
                        case 0x00:
                        case 0x01:
                        case 0x02:
                        case 0x03:
                            MBCRam[address + currMBCRAMBankPosition] = data;
                            break;
                        case 0x08:
                            if (data < 60) {
                                RTCSeconds = data;
                            } else {
                                "(Bank #'.currMBCRAMBank.') RTC write out of range: %d\n",data;
                            }
                            break;
                        case 0x09:
                            if (data < 60) {
                                RTCMinutes = data;
                            } else {
                                "(Bank #'.currMBCRAMBank.') RTC write out of range: %d\n",data;
                            }
                            break;
                        case 0x0A:
                            if (data < 24) {
                                RTCHours = data;
                            } else {
                                "(Bank #'.currMBCRAMBank.') RTC write out of range: %d\n",data;
                            }
                            break;
                        case 0x0B:
                            RTCDays = (data & 0xFF) | (RTCDays & 0x100);
                            break;
                        case 0x0C:
                            RTCDayOverFlow = (data & 0x80) == 0x80;
                            RTCHALT = (data & 0x40) == 0x40;
                            RTCDays = ((data & 0x1) << 8) | (RTCDays & 0xFF);
                            break;
                        default:
                            "Invalid MBC3 bank address selected: %d\n",currMBCRAMBank;
                    }
                }
            }
        } else {
            //We might have encountered illegal RAM writing or such, so just do nothing...
        }
    } else if (address < 0xE000) {
        //memoryWriteNormal
        memory[address] = data;
    } else if (address < 0xFE00) {
        //memoryWriteECHONormal
        memory[address - 0x2000] = data;
    } else if (address <= 0xFEA0) {
        //memoryWriteOAMRAM
        //OAM RAM cannot be written to in mode 2 & 3
        if (modeSTAT < 2) {
            memory[address] = data;
        }
    } else if (address < 0xFF00) {
        //We might have encountered illegal RAM writing or such, so just do nothing...
    //I/O Registers (GB + GBC):
    } else if (address == 0xFF00) {
        memory[0xFF00] = (data & 0x30) | ((t(((data & 0x20) == 0),(JoyPad >> 4),0xF)) & (t(((data & 0x10) == 0),(JoyPad & 0xF),0xF)));
    } else if (address == 0xFF02) {
        if (((data & 0x1) == 0x1)) {
            //Internal clock:
            memory[0xFF02] = (data & 0x7F);
            memory[0xFF0F] |= 0x8; //Get this time delayed...
        } else {
            //External clock:
            memory[0xFF02] = data;
            //No connected serial device, so don't trigger interrupt...
        }
    } else if (address == 0xFF04) {
        memory[0xFF04] = 0;
    } else if (address == 0xFF07) {
        memory[0xFF07] = data & 0x07;
        TIMAEnabled = (data & 0x04) == 0x04;
        TACClocker = 4**t(((data & 0x3) != 0),(data & 0x3),4); //TODO: Find a way to not make a conditional in here...
    } else if (address == 0xFF40) {

            temp_var = (data & 0x80) == 0x80;
            if (temp_var != LCDisOn) {
                //When the display mode changes...
                LCDisOn = temp_var;
                memory[0xFF41] &= 0xF8;
                STATTracker = modeSTAT = LCDTicks = actualScanLine = memory[0xFF44] = 0;
                if (LCDisOn) {
                    matchLYC; //Get the compare of the first scan line.
                } else {
                    displayShowOff;
                }
                memory[0xFF0F] &= 0xFD;
            }
            gfxWindowY = (data & 0x40) == 0x40;
            gfxWindowDisplay = (data & 0x20) == 0x20;
            gfxBackgroundX = (data & 0x10) == 0x10;
            gfxBackgroundY = (data & 0x08) == 0x08;
            gfxSpriteDouble = (data & 0x04) == 0x04;
            gfxSpriteShow = (data & 0x02) == 0x02;
            if ((data & 0x01) == 0) {
                // this emulates the gbc-in-gb-mode, not the original gb-mode
                bgEnabled = FALSE;
                gfxWindowDisplay = FALSE;
            } else {
                bgEnabled = TRUE;
            }
            memory[0xFF40] = data;
    } else if (address == 0xFF41) {

            LYCMatchTriggerSTAT = ((data & 0x40) == 0x40);
            mode2TriggerSTAT = ((data & 0x20) == 0x20);
            mode1TriggerSTAT = ((data & 0x10) == 0x10);
            mode0TriggerSTAT = ((data & 0x08) == 0x08);
            memory[0xFF41] = (data & 0xF8);
            if (LCDisOn && modeSTAT < 2) {
                memory[0xFF0F] |= 0x2;
            }
    } else if (address == 0xFF45) {
        memory[0xFF45] = data;
        if (LCDisOn) {
            matchLYC; //Get the compare of the first scan line.
        }
    } else if (address == 0xFF46) {
        memory[0xFF46] = data;
        //DMG cannot DMA from the ROM banks.
        if (data > 0x7F) {
            data <<= 8;
            address = 0xFE00;
            while (address < 0xFEA0) {
                memory[address++] = memoryRead(data++);
            }
        }
    } else if (address == 0xFF47) {
        if (memory[0xFF47] != data) {
            memory[0xFF47] = data;
            // BG Palette $$FF47 
            SetPal(memory[0xFF47],&bgp0,&bgp1,&bgp2,&bgp3);

            //invalidateAll(0);
        }
    } else if (address == 0xFF48) {
        if (memory[0xFF48] != data) {
            memory[0xFF48] = data;
            // OBP0 Palette $$FF48 
            SetPal(memory[0xFF48],&obp00,&obp01,&obp02,&obp03);

            //invalidateAll(1);
        }
    } else if (address == 0xFF49) {
        if (memory[0xFF49] != data) {
            memory[0xFF49] = data;
            // OBP1 Palette $$FF49 
            SetPal(memory[0xFF49],&obp10,&obp11,&obp12,&obp13);

            //invalidateAll(2);
        }
    } else if (address == 0xFF4D) {
            memory[0xFF4D] = data;
    } else if (address == 0xFF4F) {
            //Only writable by GBC.
    } else if (address == 0xFF50) {
    } else if (address == 0xFF51) {
    } else if (address == 0xFF52) {
    } else if (address == 0xFF53) {
    } else if (address == 0xFF54) {
    } else if (address == 0xFF55) {
            memory[0xFF55] = data;
    } else if (address == 0xFF68) {
            memory[0xFF68] = data;
    } else if (address == 0xFF69) {
            memory[0xFF69] = data;
    } else if (address == 0xFF6A) {
            memory[0xFF6A] = data;
    } else if (address == 0xFF6B) {
            memory[0xFF6B] = data;
    } else if (address == 0xFF6C) {
    } else if (address == 0xFF70) {
            memory[0xFF70] = data;
    } else {
        //Start the I/O initialization by filling in the slots as normal memory:
        //memoryWriteNormal
        memory[address] = data;
    }
}

U0 runInterrupt()
{
    bitShift = 0;
    testbit = 1;
    interrupts = memory[0xFFFF] & memory[0xFF0F];
    while (bitShift < 5) {
        //Check to see if an interrupt is enabled AND requested.
        if ((testbit & interrupts) == testbit) {
            IME = FALSE; //Reset the interrupt enabling.
            memory[0xFF0F] -= testbit; //Reset the interrupt request.
            //Set the stack pointer to the current program counter value:
            stackPointer = unswtuw(stackPointer - 1);
            memoryWrite(stackPointer, programCounter >> 8);
            stackPointer = unswtuw(stackPointer - 1);
            memoryWrite(stackPointer, programCounter & 0xFF);
            //Set the program counter to the interrupt's address:
            programCounter = 0x0040 + (bitShift * 0x08);
            //Interrupts have a certain clock cycle length:
            CPUTicks += 5; //People say it's around 5.
            break; //We only want the highest priority interrupt.
        }
        testbit = 1 << ++bitShift;
    }
}

// #include "LCD";

U0 updateCore()
{
    // DIV control
    DIVTicks += CPUTicks;
    if (DIVTicks >= 0x40) {
        DIVTicks -= 0x40;
        memory[0xFF04] = (memory[0xFF04] + 1) & 0xFF; // inc DIV
    }
    //LCD Controller Ticks
    I64 timedTicks = CPUTicks / multiplier;
    // LCD Timing
    LCDTicks += timedTicks; //LCD timing
    scanLine(actualScanLine); //Scan Line and STAT Mode Control
    //Audio Timing
    audioTicks += timedTicks; //Not the same as the LCD timing (Cannot be altered by display on/off changes!!!).
    //Are we past the granularity setting?
    if (audioTicks >= audioGranularity) {

        //Emulator Timing (Timed against audio for optimization):
        emulatorTicks += audioTicks;
        if (emulatorTicks >= machineCyclesPerLoop) {
                //LCD off takes at least 2 frames.
                if (drewBlank == 0) {
                    sc=InU8(0x60);
                    renderSprites; 
                    drawFrameBuffer;
                };
            stopEmulator |= 1; //End current loop.
            emulatorTicks = 0;
        }
        audioTicks = 0;
    }
    // Internal Timer
    if (TIMAEnabled) {
        timerTicks += CPUTicks;
        while (timerTicks >= TACClocker) {
            timerTicks -= TACClocker;
            if (memory[0xFF05] == 0xFF) {
                memory[0xFF05] = memory[0xFF06];
                memory[0xFF0F] |= 0x4; // set IF bit 2
            } else {
                ++memory[0xFF05];
            }
        }
    }
}

U0 opcodeRun(I64 opcode)
{
    #include "Opcode";
    //"PC:%04X \n",programCounter;
    //PressAKey;
};

U0 joyPadState(I64 key, I64 state)
{
  jp_state[key] = state;
}

U0 executeIteration()
{
    StrCpy(Fs->task_name,ROM+0x134);
    StrCpy(Fs->task_title,ROM+0x134);

    //Iterate the interpreter loop:
    I64 op = 0;
    while (sc!=1) {
        //Fetch the current opcode.
        op = memoryRead(programCounter);
        if (!skipPCIncrement) {
            //Increment the program counter to the next instruction:
            programCounter = (programCounter + 1) & 0xFFFF;
        }
        skipPCIncrement = FALSE;
        //Get how many CPU cycles the current op code counts for:
        CPUTicks = TICKTable[op];
        //Execute the OP code instruction:
        opcodeRun(op);
        //Interrupt Arming:
        switch (untilEnable) {
            case 1:
                IME = TRUE;
                // no break
            case 2:
                untilEnable--;
                // no break
        };
        //Execute Interrupt:
        if (IME) {
            runInterrupt;
        }
        //Timing:
        updateCore;
        //Keyboard
        
        switch(sc) {
            case 0x4D:
                joyPadState(0,TRUE);
                joyPadState(1,FALSE);
                break;
            case 0x4B:
                joyPadState(1,TRUE);
                joyPadState(0,FALSE);
                break;
            case 0x48:
                joyPadState(2,TRUE);
                joyPadState(3,FALSE);
                break;
            case 0x50:
                joyPadState(3,TRUE);
                joyPadState(2,FALSE);
                break;
            case 0x1F:
                joyPadState(4,TRUE);
                break;
            case 0x1E:
                joyPadState(5,TRUE);
                break;
            case 0x2A:
                joyPadState(6,TRUE);
                break;
            case 0x1C:
                joyPadState(7,TRUE);
                break;
            case 0x4D + 0x80:
                joyPadState(0,FALSE);
                break;
            case 0x4B + 0x80:
                joyPadState(1,FALSE);
                break;
            case 0x48 + 0x80:
                joyPadState(2,FALSE);
                break;
            case 0x50 + 0x80:
                joyPadState(3,FALSE);
                break;
            case 0x1F + 0x80:
                joyPadState(4,FALSE);
                break;
            case 0x1E + 0x80:
                joyPadState(5,FALSE);
                break;
            case 0x2A + 0x80:
                joyPadState(6,FALSE);
                break;
            case 0x1C + 0x80:
                joyPadState(7,FALSE);
                break;
            default:
                break;
        };

        for (keyCtr=0;keyCtr<8;keyCtr++) {
          joyPadEvent(keyCtr,jp_state[keyCtr]);
        };
        
        Sleep(0);
    };
}

U0 runEmulator()
{
    Fs->draw_it=&DrawIt;
    //The preprocessing before the actual iteration loop:
    if ((stopEmulator & 2) == 0) {
        if ((stopEmulator & 1) == 1) {
            stopEmulator = 0;
            clockUpdate; //Frame skip and RTC code.
            //If no HALT... Execute normally
            if (!halt) {
                executeIteration;
            //If we bailed out of a halt because the iteration ran down its timing.
            } else {
                CPUTicks = 1;
                opcodeRun(0x76);
                //Execute Interrupt:
                runInterrupt;
                //Timing:
                updateCore;
                executeIteration;
            }
        //We can only get here if there was an internal error, but the loop was restarted.
        } else {
            "Iterator restarted a faulted core.\n";
            PressAKey;
        }
    }
}

U0 initEmulator()
{
    programCounter = 0x100;
    stackPointer = 0xFFFE;
    IME = TRUE;
    LCDTicks = 15;
    DIVTicks = 14;
    registerA = 0x1;
    registerB = 0;
    registerC = 0x13;
    registerD = 0;
    registerE = 0xD8;
    FZero = TRUE;
    FSubtract = FALSE;
    FHalfCarry = TRUE;
    FCarry = TRUE;
    registersHL = 0x014D;
}

U0 initLCD()
{
}


#include "Cartridge";

U0 start()
{
    for (keyCtr=0;keyCtr<8;keyCtr++) {
      jp_state[keyCtr]=0;
    };
    SettingsPush;
    DocClear;
    DCFill(lcd,15);
    Fs->win_left   =0x24; 
    Fs->win_right  =0x37;
    Fs->win_top    =0x10; 
    Fs->win_bottom =0x21;
    stopEmulator=1;
    initEmulator;
    frameskipAmount = 0; //Reset the frame skip setting.
    initCart; // init cartridge bank type
    initLCD; // init LCD
    // BG Palette $$FF47 
    SetPal(memory[0xFF47],&bgp0,&bgp1,&bgp2,&bgp3);
    // OBP0 Palette $$FF48 
    SetPal(memory[0xFF48],&obp00,&obp01,&obp02,&obp03);
    // OBP1 Palette $$FF49 
    SetPal(memory[0xFF49],&obp10,&obp11,&obp12,&obp13);
    runEmulator; //Start the emulation.
    FreeLCD;
    Free(ROM);
    Fs->draw_it=NULL;    
    DCFill;
    SettingsPop;
    Kill(Fs);
}

U0 Run(U8 *rom_file)
{
    ROM=FileRead(rom_file,&ROMSize);
    start;
}