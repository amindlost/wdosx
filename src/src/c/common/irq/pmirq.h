/*
** PMIRQ.H - functions exported from PMIRQ.WDL
*/
#if !defined(__PMIRQ_H)
#define __PMIRQ_H

#ifdef __cplusplus
extern "C" {
#endif

void (*__stdcall GetIRQHandler(int))(); 
void __stdcall SetIRQHandler(int, void());

#ifdef __cplusplus
}
#endif

#endif /* __PMIRQ_H */

