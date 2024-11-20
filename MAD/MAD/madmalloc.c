//
//  madmalloc.c
//  MAD
//
//  Created by Michael on 1/5/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#include "madmalloc.h"

#import <stdlib.h>

size_t mad_malloc(char **str, size_t len) {
    size_t result = len * sizeof(char);
    *str = (char *)malloc(result);
    if (*str == NULL && len > 0) {
        fprintf(stderr, "failed to allocate memory.\n");
        //abort();
        result = 0;
    }
    return result;
}
