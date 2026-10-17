//
//  madmath.c
//  MAD
//
//  Created by Michael Thomason on 5/25/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#include "madmath.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

// All digit counting functions here.

// Recursive count of number of digits in an integer.
short digit_count_recur_int (int n) {
    if (n < 0) {
        // -INT_MIN is not representable.  Divide before negating and add the
        // digit the division dropped; the result no longer depends on INT_MIN
        // happening to have the same digit count as INT_MAX.
        if (n == INT_MIN) return 1 + digit_count_recur_int (-(n / 10));
        return digit_count_recur_int (-n);
    }
    if (n < 10) return 1;
    return 1 + digit_count_recur_int (n / 10);
}

// Recursive count of number of digits in an integer.
short digit_count_recur_uint (unsigned int n) {
    if (n < 10) return 1;
    return 1 + digit_count_recur_uint (n / 10);
}

// Iterative count of number of digits in an integer.

short digit_count_iterative_int (int n) {
    short r = 1;
    if (n < 0) {
        if (n == INT_MIN) {
            n = -(n / 10);
            r = 2;  // the dropped last digit, plus the leading digit below
        } else {
            n = -n;
        }
    }
    while (n > 9) {
        n /= 10;
        r++;
    }
    return r;
}

// Iterative count of number of digits in an unsigned integer.

short digit_count_iterative_uint (unsigned int n) {
    short r = 1;
    while (n > 9) {
        n /= 10;
        r++;
    }
    return r;
}

int32_t i32abs(int32_t i) {
    return i > 0 ? i : i * -1;
}

int64_t i64abs(int64_t i) {
    return i > 0 ? i : i * -1;
}
