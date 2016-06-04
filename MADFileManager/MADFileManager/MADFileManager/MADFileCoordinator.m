//
//  MADFileCoordinator.m
//  MADFileManager
//
//  Created by Michael Thomason on 4/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//
#import "MADFileCoordinator.h"
#import "MADLocalFileCoordinator.h"
#import "MADCloudFileCoordinator.h"
#import "MADStorageState.h"

#import <MADFoundation/MADAssert.h>

@implementation MADFileCoordinator

+ (instancetype)newFileCoordinatorWithPathExtension: (NSString *)pathExtension
                                      storageOption: (MADAppStorage)storageOption
                                         identifier: (NSString *)identifier
                                  firstQueryHandler: (void (^)(void))firstQueryHandler {
    id fileCoordinator;
    if (storageOption != MADAppStorageCloud) {
        fileCoordinator = [[MADLocalFileCoordinator alloc] initWithPathExtension: pathExtension
                                                                      identifier: identifier
                                                         firstQueryUpdateHandler: firstQueryHandler];
    }  else {
        fileCoordinator = [[MADCloudFileCoordinator alloc] initWithPathExtension: pathExtension
                                                                      identifier: identifier
                                                         firstQueryUpdateHandler: firstQueryHandler];
    }
    return fileCoordinator;
}

+ (instancetype)newFileCoordinatorWithLastPathComponent: (NSString *)lastPathComponent
                                          storageOption: (MADAppStorage)storageOption
                                             identifier: (NSString *)identifier
                                      firstQueryHandler: (void (^)(void))firstQueryHandler {
    id fileCoordinator;
    fileCoordinator = storageOption != MADAppStorageCloud ?
                [[MADLocalFileCoordinator alloc] initWithLastPathComponent: lastPathComponent
                                                                identifier: identifier
                                                   firstQueryUpdateHandler: firstQueryHandler] :
                [[MADCloudFileCoordinator alloc] initWithLastPathComponent: lastPathComponent
                                                                identifier: identifier
                                                   firstQueryUpdateHandler: firstQueryHandler];
    return fileCoordinator;
}

- (void)startQuery {
    MADAssert(NO, @"Must subclass.");
}
- (void)stopQuery {
    MADAssert(NO, @"Must subclass.");
}
- (void)removeFileAtURL:(NSURL *)URL {
    MADAssert(NO, @"Must subclass.");
}
- (void)duplicateFileAtURL:(NSURL *)URL {
    MADAssert(NO, @"Must subclass.");
}
- (void)renameFileAtURL:(NSURL *)URL toName:(NSString *)name {
    MADAssert(NO, @"Must subclass.");
}
- (void)createURLForFile:(MADFile *)list withName:(NSString *)name
               extention:(NSString *)extention fileGroup:(NSString *)fileGroup {
    MADAssert(NO, @"Must subclass.");
}
- (BOOL)canCreateFileWithName:(NSString *)name extention:(NSString *)extention
                    fileGroup:(NSString *)fileGroup {
    MADAssert(NO, @"Must subclass.");
    return NO;
}

@end
