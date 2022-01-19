/*
  ############################################################################
  ## Filename     :   dpmi32.h                                              ##
  ## Description  :   DPMI function wrappers for Borland C / WDOSX          ##
  ## Author       :   Michael Tippach                                       ##
  ## Creation Date:   1997/03/17                                            ##
  ## Last Modified:   1997/03/17                                            ##
  ############################################################################
*/

#ifndef DPMI32_H
#define DPMI32_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct { unsigned short Offset, Segment; } RMFarPtr;
typedef struct { unsigned long Offset, Selector; } PMFarPtr;
typedef struct { unsigned int edi, esi, ebp, esp, ebx, edx, ecx, eax;
                 unsigned short flags, es, ds, fs, gs, ip, cs, sp, ss;
               } RMCallStruc;

unsigned long CsSelector (void);
unsigned long SsSelector (void);
unsigned long DsSelector (void);
unsigned long EsSelector (void);
unsigned long FsSelector (void);
unsigned long GsSelector (void);

int _cdecl dpmiAllocDescriptor ( unsigned long *Selector );

int _cdecl dpmiFreeDescriptor ( unsigned long Selector );

int _cdecl dpmiSegToDescriptor ( unsigned long Segment,
                                 unsigned long *Selector );

int _cdecl dpmiGetSelectorBase ( unsigned long Selector,
                                 unsigned long *BaseAddr );

int _cdecl dpmiSetSelectorBase ( unsigned long Selector,
                                 unsigned long BaseAddr );

int _cdecl dpmiGetSelectorLimit ( unsigned long Selector,
                                  unsigned long *Limit );

int _cdecl dpmiSetSelectorLimit ( unsigned long Selector,
                                  unsigned long Limit );

int _cdecl dpmiGetAccessRights ( unsigned long Selector,
                                 unsigned long *Rights );

int _cdecl dpmiSetAccessRights ( unsigned long Selector,
                                 unsigned long Rights );

int _cdecl dpmiCreateAlias ( unsigned long Selector,
                             unsigned long *AliasSel );

int _cdecl dpmiAllocateDOSMemory ( unsigned long SizeInBytes,
                                   unsigned long *Segment,
                                   unsigned long *Selector );

int _cdecl dpmiFreeDOSMemory ( unsigned long Selector );

int _cdecl dpmiResizeDOSMemory ( unsigned long Selector,
                                 unsigned long NewSize );

int _cdecl dpmiGetRMVector ( int IntNum, RMFarPtr *IntVec );

int _cdecl dpmiSetRMVector ( int IntNum, RMFarPtr *IntVec );

int _cdecl dpmiGetPMVector ( int IntNum, PMFarPtr *IntVec );

int _cdecl dpmiSetPMVector ( int IntNum, PMFarPtr *IntVec );

int _cdecl dpmiSimulateInterrupt ( int IntNum, RMCallStruc *RmRegs );

int _cdecl dpmiAllocateCallback ( RMFarPtr *CallbackAddr,
                                   void *CallbackFunc,
                                   RMCallStruc *CallbackStruc);

int _cdecl dpmiFreeCallback ( RMFarPtr *CallbackAddr );

unsigned short _cdecl dpmiGetIntFromIRQ ( unsigned short IRQNum );

int _cdecl dpmiLockLinearRegion ( unsigned long LockStart,
                                  unsigned long LockSize  );

int _cdecl dpmiUnlockLinearRegion ( unsigned long UnlockStart,
                                    unsigned long UnlockSize );

int _cdecl dpmiMapPhysicalRegion ( unsigned long MapStart,
                                   unsigned long MapSize,
                                   unsigned long *MapLinear );

#ifdef __cplusplus
}
#endif

#endif	/* DPMI32_H */
