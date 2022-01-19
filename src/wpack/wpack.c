/**************************************************************************
*
* $Header: E:/RCS/WDOSX/0.95/SRC/WPACK/wpack.c 1.3 2003/06/17 10:38:14 MikeT Exp MikeT $
*
***************************************************************************
*
* $Log: wpack.c $
* Revision 1.3  2003/06/17 10:38:14  MikeT
* Update Jibz header comment.
*
* Revision 1.2  2001/02/22 22:21:01  MikeT
* New version - 1.07
*
* Revision 1.1  1999/06/20 15:41:44  MikeT
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

#include "wpack.h"

#define LEN_2_LIMIT 1920

typedef struct MATCH {
        int pos;
        int len;
} MATCH;

/* global variables used */
unsigned int nextbackentry;
unsigned char *backptr;
unsigned char *source_offs;

unsigned char *inbuffer, *outbuffer, *tagbyte;
unsigned int bitcount;

/* back-table */
unsigned int *backtable;

/* lookup-table */
unsigned int lookup[256][256];

unsigned int lastmatchpos;

unsigned int lastwasmatch;

/*========================================================================
   PACKING FUNCTIONS
  ========================================================================*/

static void advancetagbyte(int bit)
{
   /* check bitcount and then decrement */
   if (!bitcount--)
   {
      bitcount = 7;
      tagbyte = outbuffer++;
   }

   /* shift in bit */
   if (bit)
   {
      *tagbyte = ((*tagbyte) << 1) + 0x01;
   } else {
      *tagbyte = (*tagbyte) << 1;
   }
}

/* Output Gamma2-code for val in range [2..?] ... */
static void outputGAMMA(unsigned int val)
{
   int invertlen = 0;
   unsigned int invert;

   /* rotate bits into invert (except last) */
   do {
      invert = (invert << 1) | (val & 0x0001);
      invertlen++;
   } while ((val >>= 1) > 1);

   /* output Gamma2-encoded bits */
   while (--invertlen)
   {
      advancetagbyte(invert & 0x0001);
      advancetagbyte(1);
      invert >>= 1;
   }
   advancetagbyte(invert & 0x0001);
   advancetagbyte(0);
}

void outputLITERAL(unsigned char lit)
{
   lastwasmatch = 0;

   /* 0 indicates a literal */
   advancetagbyte(0);

   /* output the literal */
   *outbuffer = lit;
   outbuffer++;
}

void outputCODEPAIR(unsigned int pos, unsigned int len, unsigned char *buffer)
{
   /* if we just had a match, don't use lastmatchpos */
   if (lastwasmatch != 0)
   {
      /* if a short match is too far away, encode it as two literals instead */
      if ((pos > LEN_2_LIMIT) && (len == 2))
      {
         outputLITERAL(*(buffer));
         outputLITERAL(*(buffer + 1));

      } else {

         /* 1 indicates a match */
         advancetagbyte(1);

         /* a match more than LEN_2_LIMIT bytes back will be longer than 2 */
         if (pos > LEN_2_LIMIT) len--;

         /* output length */
         outputGAMMA(len);

         lastmatchpos = pos;
         pos--;

         /* output high part of position */
         outputGAMMA((pos >> 6) + 2);

         /* output low 6 bits of position */
         advancetagbyte(pos & 0x0020);
         advancetagbyte(pos & 0x0010);
         advancetagbyte(pos & 0x0008);
         advancetagbyte(pos & 0x0004);
         advancetagbyte(pos & 0x0002);
         advancetagbyte(pos & 0x0001);
      }

   } else {

      lastwasmatch = 1;

      /* if a short match is too far away, encode it as two literals instead */
      if ((pos > LEN_2_LIMIT) && (len == 2) && (pos != lastmatchpos))
      {
         outputLITERAL(*(buffer));
         outputLITERAL(*(buffer + 1));

      } else {

         /* 1 indicates a match */
         advancetagbyte(1);

         /* a match more than LEN_2_LIMIT bytes back will be longer than 2 */
         if ((pos > LEN_2_LIMIT) && (pos != lastmatchpos)) len--;

         /* output length */
         outputGAMMA(len);

         /* output position */
         if (pos == lastmatchpos)
         {
            /* a match with position 0 means use last position */
            advancetagbyte(0);
            advancetagbyte(0);

         } else {

            lastmatchpos = pos;
            pos--;

            /* output high part of position */
            outputGAMMA((pos >> 6) + 3);

            /* output low 6 bits of position */
            advancetagbyte(pos & 0x0020);
            advancetagbyte(pos & 0x0010);
            advancetagbyte(pos & 0x0008);
            advancetagbyte(pos & 0x0004);
            advancetagbyte(pos & 0x0002);
            advancetagbyte(pos & 0x0001);
         }
      }
   }
}

void outputEOD()
{
   /* just switch last tagbyte into position */
   *tagbyte = (*tagbyte) << bitcount;
}

static void findmatch(MATCH *thematch, unsigned char *buffer, unsigned int lookback, unsigned int lookforward)
{
   unsigned int backpos;
   unsigned char *ptr;

   /* temporary variables to avoid indirect addressing into thematch */
   unsigned int bestmatchlen = 0;
   unsigned int bestmatchpos = 0;

   unsigned int matchlen;

   /* update lookup- and backtable up to current position */
   while (backptr < buffer)
   {
      backtable[nextbackentry] = lookup[(*backptr)][(*(backptr + 1))];

      lookup[(*backptr)][(*(backptr + 1))] = nextbackentry;

      nextbackentry++;
      backptr++;
   }

   /* get position by looking up next two bytes */
   backpos = lookup[(*buffer)][(*(buffer + 1))];

   if ((backpos) && (lookforward > 1))
   {
      ptr = backpos + source_offs;

      /* go backwards until before buffer */
      while ((ptr >= buffer) && (backpos))
      {
         backpos = backtable[backpos];
         ptr = backpos + source_offs;
      }

      /* search through table entries */
      while ((backpos) && (buffer - ptr <= lookback))
      {
         matchlen = 2;
         /* if this position has a chance to be better */
         if (*(ptr + bestmatchlen) == *(buffer + bestmatchlen))
         {
            /* scan it */
            while ((*(ptr + matchlen) == *(buffer + matchlen)) && (matchlen < lookforward))
            {
               matchlen++;
            }

            /* check it */
            if (matchlen + (buffer - ptr == lastmatchpos) > bestmatchlen + (bestmatchpos == lastmatchpos))
            {
               bestmatchlen = matchlen;
               if (bestmatchlen == lookforward) backpos = 0;
               bestmatchpos = buffer - ptr;
            }
         }

         /* move backwards to next position */
         backpos = backtable[backpos];
         ptr = backpos + source_offs;

      } /* while ((backpos) && (buffer - ptr <= lookback)) */

   } /* if ((backpos) && (lookforward > 1)) */

   /* forget match if too far away */
   if ((bestmatchpos > LEN_2_LIMIT) && (bestmatchlen == 2) && (bestmatchpos != lastmatchpos))
   {
      bestmatchlen = 0;
      bestmatchpos = 0;
   }

   /* update thematch with best match */
   thematch->len = bestmatchlen;
   thematch->pos = bestmatchpos;
}

/*========================================================================
   MAIN FUNCTION
  ========================================================================*/

unsigned int WdosxPack(unsigned char *source,
                       unsigned char *destination,
                       unsigned char *workmem,
                       unsigned int length)
{
   MATCH match, nextmatch, literalmatch, testmatch;
   unsigned int pos, lastpos, literalcount;

   unsigned int i, j;

   source_offs = source - 1;
   inbuffer = source;
   outbuffer = destination;

   backtable = (unsigned int *) (workmem);

   /* init lookup- and backtable */
   for (i = 0; i < 256; i++) for (j = 0; j < 256; j++) lookup[i][j] = 0;
   backptr = inbuffer;
   backtable[0] = 0;
   nextbackentry = 1;

   lastpos = -1;
   lastmatchpos = -1;
   lastwasmatch = 0;
   literalcount = 0;

   /* the first byte is sent verbatim */
   *outbuffer = *inbuffer;
   outbuffer++;
   inbuffer++;

   /* init tag-byte */
   bitcount = 8;
   tagbyte = outbuffer++;

   /* pack data */
   for (pos = 1; pos < length; )
   {
      /* find best match at current position (if not allready found) */
      if (pos == lastpos)
      {
         match.len = nextmatch.len;
         match.pos = nextmatch.pos;
      } else {
         findmatch(&match, inbuffer, pos, length - pos);
      }

      /* if we found a match, find the best match at the next position */
      if (match.len)
      {
         findmatch(&nextmatch, inbuffer + 1, pos + 1, length - (pos + 1));
         lastpos = pos + 1;
      } else nextmatch.len = 0;

      /* decide if we should output a match or a literal */
      if ((match.len) &&
          (match.len + (match.pos == lastmatchpos) >= nextmatch.len + (nextmatch.pos == lastmatchpos)))
      {
         /* output any pending literals */
         if (literalcount)
         {
            if (literalcount == 1)
            {
               outputLITERAL(*(inbuffer - 1));
            } else {
               /* check if there is a closer match with the required length */
               findmatch(&testmatch, inbuffer - literalcount, literalmatch.pos, literalcount);

               if (testmatch.len >= literalcount)
               {
                  outputCODEPAIR(testmatch.pos, literalcount, inbuffer - literalcount);
               } else {
                  outputCODEPAIR(literalmatch.pos, literalcount, inbuffer - literalcount);
               }
            }
            literalcount = 0;
         }
         /* output match */
         outputCODEPAIR(match.pos, match.len, inbuffer);
         inbuffer += match.len;
         pos += match.len;

      } else { /* if ((match.len) && ( ... ) */

         /* check if we are allready collecting literals */
         if (literalcount)
         {
            /* if so, continue.. */
            literalcount++;
            /* have we collected as many as possible? */
            if (literalcount == literalmatch.len)
            {
               outputCODEPAIR(literalmatch.pos, literalcount, inbuffer - literalcount + 1);
               literalcount = 0;
            }

         } else { /* if (literalcount) */

            /* if we had a match which was not good enough, then save it.. */
            if (match.len)
            {
               literalmatch.len = match.len;
               literalmatch.pos = match.pos;
               literalcount++;
            } else {
               /* if not, we have to output the literal now */
               outputLITERAL(*inbuffer);
            }
         } /* if (literalcount) */
         inbuffer++;
         pos++;
      } /* if ((match.len) && ( ... ) */
   }

   /* output any remaining literal bytes */
   if (literalcount)
   {
      if (literalcount == 1)
      {
         outputLITERAL(*(inbuffer - 1));
      } else {
         outputCODEPAIR(literalmatch.pos, literalcount, inbuffer - literalcount);
      }
      literalcount = 0;
   }

   /* do EOD stuff */
   outputEOD();

   return(outbuffer - destination);
}

/*========================================================================
   END
  ========================================================================*/
