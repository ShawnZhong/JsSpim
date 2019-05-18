/* SPIM S20 MIPS simulator.
  Append-only output stream convertable to a string.

   Copyright (c) 1990-2010, James R. Larus.
   All rights reserved.

   Redistribution and use in source and binary forms, with or without modification,
   are permitted provided that the following conditions are met:

   Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

   Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation and/or
   other materials provided with the distribution.

   Neither the name of the James R. Larus nor the names of its contributors may be
   used to endorse or promote products derived from this software without specific
   prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
   GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
   HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
   LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
   OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


#include <stdlib.h>
#include <stdarg.h>
#include <stdio.h>

#include "spim.h"
#include "string-stream.h"


#ifndef SS_BUF_LENGTH
/* Initialize length of buffer */
#define SS_BUF_LENGTH 256
#endif


void
ss_init (str_stream* ss)
{
  ss->buf = (char *) malloc (SS_BUF_LENGTH);
  ss->max_length = SS_BUF_LENGTH;
  ss->empty_pos = 0;
  ss->initialized = 1;
}


void
ss_clear (str_stream* ss)
{
  if (0 == ss->initialized) ss_init (ss);

  ss->empty_pos = 0;
}


void
ss_erase (str_stream* ss, int n)
{
  if (0 == ss->initialized) ss_init (ss);

  ss->empty_pos -= n;
  if (ss->empty_pos <0) ss->empty_pos = 0;
}


int
ss_length (str_stream* ss)
{
  if (0 == ss->initialized) ss_init (ss);

  return ss->empty_pos;
}


char*
ss_to_string (str_stream* ss)
{
  if (0 == ss->initialized) ss_init (ss);

  if (ss->empty_pos == ss->max_length)
    {
      /* Not enough room to store output: increase buffer size and try again */
      ss->max_length = ss->max_length + 1;
      ss->buf = (char *) realloc (ss->buf, (size_t)ss->max_length);
      if (NULL == ss->buf)
	fatal_error ("realloc failed\n");
    }
  ss->buf[ss->empty_pos] = '\0'; /* Null terminate string */
  ss->empty_pos += 1;
  return ss->buf;
}


void
ss_printf (str_stream* ss, char* fmt, ...)
{
  int free_space;
  int n;
  va_list args;

  va_start (args, fmt);

  if (0 == ss->initialized) ss_init (ss);

  free_space = ss->max_length - ss->empty_pos;
#ifdef _WIN32
  /* Returns -1 when buffer is too small */
  while ((n = _vsnprintf (ss->buf + ss->empty_pos, free_space, fmt, args)) < 0)
#else
    /* Returns necessary space when buffer is too small */
   while ((n = vsnprintf (ss->buf + ss->empty_pos, free_space, fmt, args)) >= free_space)
#endif
      {
	/* Not enough room to store output: double buffer size and try again */
	ss->max_length = 2 * ss->max_length;
	ss->buf = (char *) realloc (ss->buf, (size_t)ss->max_length);
	free_space = ss->max_length - ss->empty_pos;
	if (NULL == ss->buf)
	  fatal_error ("realloc failed\n");

	va_end (args);		/* Restart argument pointer */
	va_start (args, fmt);
      }
  ss->empty_pos += n;

  /* Null terminate string (for debugging) if there is enough room*/
  if (ss->empty_pos < ss->max_length)
    ss->buf[ss->empty_pos] = '\0';

  va_end (args);
}
