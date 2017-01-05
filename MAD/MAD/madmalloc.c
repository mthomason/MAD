//
//  madmalloc.c
//  MAD
//
//  Created by Michael on 1/5/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#include "madmalloc.h"

#import <stdlib.h>

void mad_malloc(char **str, size_t len) {
    *str = (char *)malloc(len * sizeof(char));
    if (*str == NULL && len > 0) {
        fprintf(stderr, "failed to allocate memory.\n");
        abort();
    }
}
