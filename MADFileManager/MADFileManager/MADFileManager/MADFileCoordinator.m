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
    if (storageOption != MADAppStorageCloud) {
        return [[MADLocalFileCoordinator alloc] initWithLastPathComponent: lastPathComponent
                                                               identifier: identifier
                                                  firstQueryUpdateHandler: firstQueryHandler];
    } else {
        return [[MADCloudFileCoordinator alloc] initWithLastPathComponent: lastPathComponent
                                                               identifier: identifier
                                                  firstQueryUpdateHandler: firstQueryHandler];
    }
}

@end
