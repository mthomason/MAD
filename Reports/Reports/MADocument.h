 
 
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

extern NSString * const MTDocumentInfoKeyThumbnail;

@interface MADocument : UIManagedDocument

- (void)quickSave;
- (void)saveContext;
- (void)deleteFromDiskCompletion:(void (^)(BOOL success))completion;
+ (void)deleteFromDisk:(NSURL *)fileUrl completion:(void (^)(BOOL success))completion;
+ (void)deleteFromDiskQuick:(MADocument *)documentReport completion:(void (^)(BOOL success))completion;
- (NSString *)name;
- (NSString *)fileName;
+ (NSString *)fileNameForMadUrl:(NSURL *)madUrl;
+ (NSString *)thumbnailSaveName;

- (NSURL *)urlThumbnail;

@property (nonatomic, assign, getter = isSuspended) BOOL suspended;

@end

#endif
