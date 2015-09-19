//
//  MADLocalFileCoordinator.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDesigner_MADLocalFileCoordinator_h
#define MADDesigner_MADLocalFileCoordinator_h

#import <Foundation/Foundation.h>
#import <MADFoundation/NSFileManager+Common.h>
#import "MADFileCoordinator.h"

@interface MADLocalFileCoordinator : NSObject <MADFileCoordinator>

- (instancetype)initWithPathExtension:(NSString *)pathExtension identifier:(NSString *)fileGroup
              firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler;

- (instancetype)initWithLastPathComponent:(NSString *)lastPathComponent identifier:(NSString *)fileGroup
                  firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler;

@end

#endif
