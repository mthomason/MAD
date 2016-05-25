//
//  madlib.c
//  MAD
//
//  Created by Michael Thomason on 5/17/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "madlib.h"
#import <stdlib.h>
#import <stdio.h>
#import <strings.h>

void ultoa(unsigned long n, char s[]) {
    int i = 0;
    do {                            /* generate digits in reverse order */
        s[i++] = n % 10 + '0';      /* get next digit */
    } while ((n /= 10) > 0);        /* delete it */
    s[i] = '\0';
    reverse(s);
}

void uitoa(unsigned int n, char s[]) {
    int i = 0;
    do {                            /* generate digits in reverse order */
        s[i++] = n % 10 + '0';      /* get next digit */
    } while ((n /= 10) > 0);        /* delete it */
    s[i] = '\0';
    reverse(s);
}

void itoa(int n, char s[]) {
    int i, sign;
    
    if ((sign = n) < 0)  /* record sign */
        n = -n;          /* make n positive */
    i = 0;
    do {                            /* generate digits in reverse order */
        s[i++] = n % 10 + '0';      /* get next digit */
    } while ((n /= 10) > 0);        /* delete it */
    if (sign < 0)
        s[i++] = '-';
    s[i] = '\0';
    reverse(s);
}

void reverse(char s[]) {
    unsigned long i; size_t j;
    char c;
    for (i = 0, j = strlen(s) - 1; i < j; i++, j--) {
        c = s[i];
        s[i] = s[j];
        s[j] = c;
    }
}
