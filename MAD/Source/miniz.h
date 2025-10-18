//
//  madmini.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/13/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef miniz_h
#define miniz_h

#include <stdio.h>

// ------------------- Types and macros

// Compression levels: 0-9 are the standard zlib-style levels, 10 is best possible compression (not zlib compatible, and may be very slow), MZ_DEFAULT_COMPRESSION=MZ_DEFAULT_LEVEL.
enum { MZ_NO_COMPRESSION = 0, MZ_BEST_SPEED = 1, MZ_BEST_COMPRESSION = 9, MZ_UBER_COMPRESSION = 10, MZ_DEFAULT_LEVEL = 6, MZ_DEFAULT_COMPRESSION = -1 };

typedef unsigned char mz_uint8;
typedef signed short mz_int16;
typedef unsigned short mz_uint16;
typedef unsigned int mz_uint32;
typedef unsigned int mz_uint;
typedef long long mz_int64;
typedef unsigned long long mz_uint64;
typedef int mz_bool;

void *tdefl_write_image_to_png_file_in_memory_ex(const void *pImage, int w, int h, int num_chans,
                                                 size_t *pLen_out, mz_uint level, mz_bool flip);

#endif /* madmini_h */
