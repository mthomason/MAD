//
//  madpath.h
//  MAD
//
//  Created by Michael Thomason on 5/22/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef madpath_h
#define madpath_h

int mad_file_remove_if_exist(char *path);
int mad_path_is_absolute(const char *path);
int mad_path_is_relative(const char *path);

#endif /* madpath_h */
