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
#import <MADFileManager/MADAppStorageOption.h>
#import "MADFileCoordinatorProtocol.h"

@interface MADFileCoordinator : NSObject <MADFileCoordinatorProtocol>

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
