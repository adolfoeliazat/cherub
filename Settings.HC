I64 audioGranularity = 20;

//Auto Frame Skip
I64 autoFrameskip = TRUE;

//Colorize GB mode? **No CGB support**
I64 colorize = FALSE;

//Keyboard button map. **Not implemented yet**
//Order: Right, Left, Up, Down, A, B, Select, Start
I64 keyboardButtonMap[8] = {'d', 'a', 'w', 's', ',', '.', 'n', 'm'};

//Frameskip Amount (Auto frameskip setting allows the script to change this.)
I64 frameskipAmount = 0;

//Frameskip base factor
I64 frameskipBaseFactor = 10;

//Maximum Frame Skip
I64 frameskipMax = 29;

//Interval for the emulator loop.
I64 loopInterval = 17;

//Target number of machine cycles per loop. (4,194,300 / 1000 * 17)
I64 machineCyclesPerLoop = 17826;

//Override MBC RAM disabling and always allow reading and writing to the banks.
I64 overrideMBC = TRUE;

//Override to allow for MBC1 instead of ROM only (compatibility for broken 3rd-party cartridges).
I64 overrideMBC1 = TRUE;

//Give priority to GameBoy mode
I64 priorizeGameBoyMode = TRUE;

//Sample Rate
I64 sampleRate = 70000;
