/**************************************************************************
*
* $Header: E:/RCS/WDOSX/0.95/SRC/WPACK/wpack.h 1.3 2003/06/17 10:38:54 MikeT Exp MikeT $
*
***************************************************************************
*
* $Log: wpack.h $
* Revision 1.3  2003/06/17 10:38:54  MikeT
* Update Jibz header comment.
*
* Revision 1.2  2001/02/22 22:20:43  MikeT
* New version - 1.07
*
* Revision 1.1  1999/06/20 15:43:14  MikeT
* Initial check in.
*
*
***************************************************************************/

/*
 * WDOSX-Pack v1.07
 *
 * Copyright (c) 1999-2003 by Joergen Ibsen / Jibz
 * All Rights Reserved
 *
 * http://www.ibsensoftware.com/
 */

/*
   Notes
   -----

   - The workmem should be (length+2)*4 bytes (assuming an unsigned int
     is 4 bytes).

   - Uncompressible data may be expanded by up to 1 bit per byte. This
     means that the destination should be length+((length+7)/8)+2 bytes.

   - The depacker can handle compressed blocks of up to about 64k.

*/

#ifndef __WDOSXPACK_H
#define __WDOSXPACK_H

#ifdef __cplusplus
extern "C" {
#endif

/* function prototype */
unsigned int WdosxPack(unsigned char *source,
                       unsigned char *destination,
                       unsigned char *workmem,
                       unsigned int length
                      );

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif
