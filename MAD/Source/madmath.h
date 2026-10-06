//
//  madmath.h
//  MAD
//
//  Created by Michael Thomason on 5/25/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef madmath_h
#define madmath_h

#include <stdint.h>
#include <stdio.h>
#include <limits.h>

short digit_count_recur_int       (int n);
short digit_count_recur_uint      (unsigned int n);
short digit_count_iterative_int   (int n);
short digit_count_iterative_uint  (unsigned int n);

int64_t i64abs(int64_t i);
int32_t i32abs(int32_t i);

#endif /* madmath_h */
