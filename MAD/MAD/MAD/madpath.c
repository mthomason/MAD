//
//  madpath.c
//  MAD
//
//  Created by Michael Thomason on 5/22/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#include "madpath.h"
#include <string.h>
#include <stdio.h>
#include <unistd.h>

int mad_file_remove_if_exist(char *path) {
    //printf("mad_file_if_exist(char *path)\n%s\nstrlen(%d)", path, strlen(path));
    return (access(path, F_OK) == 0) ?
            remove(path) :
            -1;
}

int mad_path_is_absolute(const char *path) {
    return strlen(path) > 1 && path[0] == '/' ? 1 : 0;
}

int mad_path_is_relative(const char *path) {
    return mad_path_is_absolute(path) ? 0 : 1;
}
