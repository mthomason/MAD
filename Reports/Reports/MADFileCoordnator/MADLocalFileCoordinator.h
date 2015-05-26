//
//  MADLocalFileCoordinator.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MADFileCoordinator.h"

@interface MADLocalFileCoordinator : NSObject <MADFileCoordinator>

- (instancetype)initWithPathExtension:(NSString *)pathExtension
              firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler;

- (instancetype)initWithLastPathComponent:(NSString *)lastPathComponent
                  firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler;

@end
