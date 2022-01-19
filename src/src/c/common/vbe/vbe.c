#include <conio.h>
#include "dpmi32.h"

//
// This short example will establish a VESA mode 0x0101 screen in linear frame
// buffer mode and draw a line there. 
//
// No, I repeat: NO error checking is beeing done so expect the code to go
// ballistic if you graphics card is not VESA 2 compliant, does not support
// 640 * 480 LFB or if you're running this in an NT DOS box.
//
// This "code" has been tested with both, BC++ and MSVC++ yielding identical
// results. We deliberately chose to _not_ use _any_ assembly here.
//
// And: yes, it _is_ silly, if you've done stuff like this before.
//

int main (int argc, char *argv[], char *env[] )
{

// Variables

RMCallStruc rmcall;
unsigned char *screen;
unsigned long RealSeg;
unsigned long DosSel;
int i;

// Allocate some DOS memory

dpmiAllocateDOSMemory (256, &RealSeg, &DosSel);

// Preload rmcall register structure

rmcall.ss = 0;
rmcall.sp = 0;
rmcall.es = (unsigned short) RealSeg;
rmcall.edi = 0;
rmcall.eax = 0x4F01;
rmcall.ecx = 0x0101;

// Call the VESA BIOS

dpmiSimulateInterrupt(0x10, &rmcall);

// Get the pointer to the LFB

dpmiMapPhysicalRegion ( * (unsigned long *) ((RealSeg << 4) + 40), \
                       640 * 480, (unsigned long *) &screen);

// Free the DOS memory block as we don't need it any more

dpmiFreeDOSMemory(DosSel);

// Set the video mode. This could be done with 3 lines of
// inline assembly but we don't want to use any assembly here

rmcall.ebx = 0x4101;
rmcall.eax = 0x4F02;
dpmiSimulateInterrupt(0x10, &rmcall);

// Now draw some pixels

for (i = 0; i < (640 * 480); i += 641) screen[i] = (unsigned char) 0x7;

// ...wait for a key

while (!kbhit());

// Set video mode back to text mode. Again, this could be done
// with only two lines of inline assembly...

rmcall.eax = 0x0003;
dpmiSimulateInterrupt(0x10, &rmcall);

return (0);
}
