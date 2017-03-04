//
//  madlib.h
//  MAD
//
//  Created by Michael Thomason on 5/17/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef madlib_h
#define madlib_h

#include <stdio.h>

int ultoa(unsigned long n, char s[]);
void uitoa(unsigned int n, char s[]);
void itoa(int n, char s[]);
void reverse(char s[]);
void ltoa(long n, char s[]);

unsigned long count_digits_ul(unsigned long i);
int count_digits(int);

#endif /* madlib_h */
