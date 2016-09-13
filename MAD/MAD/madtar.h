//
//  madtar.h
//  MAD
//
//  Created by Michael Thomason on 5/19/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef madtar_h
#define madtar_h

#import <archive.h>

int mad_copy_data(struct archive *ar, struct archive *aw);
int mad_extract(const char *filename);
void mad_archive_entry_set_attributes(struct archive_entry **e, struct stat *st);
void mad_archive_write_file(struct archive *archive, const char *filename, const char *relativePath);

#endif /* madtar_h */
