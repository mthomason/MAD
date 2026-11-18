//
//  madlib.h
//  MAD
//
//  Created by Michael Thomason on 5/17/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef madlib_h
#define madlib_h

#include <stdio.h>

int mad_ultoa(unsigned long n, char s[]);
void uitoa(unsigned int n, char s[]);
void mad_itoa(int n, char s[]);
void reverse(char s[]);
void mad_ltoa(long n, char s[]);

unsigned long count_digits_ul(unsigned long i);
int count_digits(int);

#endif /* madlib_h */
