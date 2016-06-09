//
//  NSURL+Document.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_NSURL_Document_h
#define Reports_NSURL_Document_h

#import <Foundation/NSURL.h>

@interface NSURL (Document)

    + (instancetype)newURLCacheFilesDirectoryForFilename:(NSString *)filename;
    + (instancetype)newURLDocumentArchiveForFileURL:(NSURL *)madUrl
                                          extension:(NSString *)extension;

    + (instancetype)newThumbnailUrlForMadUrl:(NSURL *)madUrl;

    + (instancetype)newUrlThumbnailForHandle:(NSString *)handle
                            andRetinaDisplay:(BOOL)retinaDisplay;

    - (NSURL *)uniqueUrl;
    - (NSString *)key;
    + (NSString *)newStringFileNameFilter:(NSString *)desiredName;

@end

#endif
