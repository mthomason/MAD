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

- (NSString *)filenameMinusExtention;
- (NSURL *)uniqueUrl;
- (NSString *)key;
+ (NSString *)fileNameFilter:(NSString *)desiredName;

@end

#endif
