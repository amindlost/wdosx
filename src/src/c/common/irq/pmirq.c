/*
** Usage example for PMIRQ.WDL. Sets a new timer handler (IRQ 0) and increments
** the character value in the upper left screen corner.
*/
#include "pmirq.h"
#include <conio.h>

void (*OldHandler)();

void NewHandler() {
   unsigned char *p;
   p = 0xB8000;
   ++ (*p);
   OldHandler();
}

int main() {
   OldHandler = GetIRQHandler(0);
   SetIRQHandler(0, NewHandler);
   while (!kbhit());
   SetIRQHandler(0, OldHandler);
   return(0);
}
