//
//  MADLocalFileCoordinator.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADDesigner_MADLocalFileCoordinator_h
#define MADDesigner_MADLocalFileCoordinator_h

#import "MADFileCoordinator.h"

@interface MADLocalFileCoordinator : NSObject <MADFileCoordinatorProtocol>

    - (instancetype)initWithPathExtension: (NSString *)pathExtension
                               identifier: (NSString *)fileGroup
                  firstQueryUpdateHandler: (void (^)(void))firstQueryUpdateHandler;

    - (instancetype)initWithLastPathComponent: (NSString *)lastPathComponent
                                   identifier: (NSString *)fileGroup
                      firstQueryUpdateHandler: (void (^)(void))firstQueryUpdateHandler;

@end

#endif
