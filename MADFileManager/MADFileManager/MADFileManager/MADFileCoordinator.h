//
//  MADFileCoordinator.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADFileCoordinator_h
#define MAD_Designer_MADFileCoordinator_h

#import <Foundation/NSObject.h>
#import "MADStorageState.h"

@class MADFile;

typedef NSArray <NSURL *> MADURLArray;

@protocol MADFileCoordinatorDelegate;

@protocol MADFileCoordinator <NSObject>

    @property (nonatomic, weak) id <MADFileCoordinatorDelegate> delegate;
    @property (nonatomic, strong, readwrite) NSURL *documentsDirectory;

    - (void)startQuery;
    - (void)stopQuery;
    - (void)removeFileAtURL:(NSURL *)URL;
    - (void)duplicateFileAtURL:(NSURL *)URL;
    - (void)renameFileAtURL:(NSURL *)URL toName:(NSString *)name;
    - (void)createURLForFile:(MADFile *)list withName:(NSString *)name
                   extention:(NSString *)extention fileGroup:(NSString *)fileGroup;
    - (BOOL)canCreateFileWithName:(NSString *)name extention:(NSString *)extention
                        fileGroup:(NSString *)fileGroup;

@end

@interface MADFileCoordinator : NSObject <MADFileCoordinator>

    + (instancetype)newFileCoordinatorWithPathExtension: (NSString *)pathExtension
                                          storageOption: (MADAppStorage)storageOption
                                             identifier: (NSString *)identifier
                                      firstQueryHandler: (void (^)(void))firstQueryHandler;

    + (instancetype)newFileCoordinatorWithLastPathComponent: (NSString *)lastPathComponent
                                              storageOption: (MADAppStorage)storageOption
                                                 identifier: (NSString *)identifier
                                          firstQueryHandler: (void (^)(void))firstQueryHandler;
@end

#endif
