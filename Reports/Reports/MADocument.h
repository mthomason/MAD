 
 
//
//  MNSDocument.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADocument_h
#define Reports_MADocument_h

#import <Foundation/Foundation.h>
#import "MTCacheProtocol.h"

extern NSString * const MTDocumentInfoKeyThumbnail;

@class MADocumentState;

@interface MADocument : UIManagedDocument
    <MTCacheProtocol>

@property (nonatomic, strong, readwrite) MADocumentState *documentStatus;

- (void)quickSave;
- (void)saveContext;
- (void)deleteFromDiskCompletion:(void (^)(BOOL success))completion;
- (NSString *)name;
- (NSString *)fileName;
+ (NSString *)fileNameForMadUrl:(NSURL *)madUrl;

- (NSURL *)urlThumbnail;
- (void)wrapFileOverwrite:(BOOL)overwrite completion:(void (^)(BOOL success, NSURL *resultUrl))completion;

@end

#endif
