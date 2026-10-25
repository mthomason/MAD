//
//  madtar.h
//  MAD
//
//  Created by Michael Thomason on 5/19/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef madtar_h
#define madtar_h

#import <libxml2/libxml/list.h>

#import "archive.h"

/// The modification time every member carries in a reproducible archive: 2001-01-12
/// 00:00:00 UTC, the instant MADCLIPinPDFMetadata pins a PDF's dates to.  A constant
/// rather than the file's own mtime, which is what makes two archives of the same
/// members equal (BUGS.md, the .mad byte-identity entry).
#define MADArchiveReproducibleModificationTime 979257600

int mad_copy_data(struct archive *, struct archive *);
int mad_extract(const char *, const char *, const char *);
void mad_archive_entry_set_attributes(struct archive_entry **, struct stat *, int reproducible);
int mad_archive_write_file(struct archive *, const char *, const char *, int reproducible);

#endif /* madtar_h */
