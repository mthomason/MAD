//
//  madmath.h
//  MAD
//
//  Created by Michael Thomason on 5/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef madmath_h
#define madmath_h

#include <stdio.h>
#include <limits.h>

short digit_count_recur_int       (int n);
short digit_count_recur_uint      (unsigned int n);
short digit_count_iterative_int   (int n);
short digit_count_iterative_uint  (unsigned int n);

#endif /* madmath_h */
