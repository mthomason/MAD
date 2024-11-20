//
//  madtar.h
//  MAD
//
//  Created by Michael Thomason on 5/19/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef madtar_h
#define madtar_h

#import "archive.h"

int mad_copy_data(struct archive *, struct archive *);
int mad_extract(const char *, const char *, const char *);
void mad_archive_entry_set_attributes(struct archive_entry **, struct stat *);
int mad_archive_write_file(struct archive *, const char *, const char *);

#endif /* madtar_h */
