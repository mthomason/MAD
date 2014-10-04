//
//  NSURL+Document.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_NSURL_Document_h
#define Reports_NSURL_Document_h

#import <Foundation/Foundation.h>

@interface NSURL (Document)

- (NSString *)filenameMinusExtention;
+ (NSURL *)uniqueUrlInDirectory:(NSURL *)directory withDesiredHandle:(NSString *)desiredFileHandle andExtension:(NSString *)extension;
- (NSString *)key;

@end

#endif
