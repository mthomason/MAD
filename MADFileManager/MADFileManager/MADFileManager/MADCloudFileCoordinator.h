//
//  MADCloudFileCoordinator.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDesigner_MADCloudFileCoordinator_h
#define MADDesigner_MADCloudFileCoordinator_h

#import <Foundation/Foundation.h>
#import <MADCocoaExtensions/MADCocoaExtensions.h>
#import "MADFileCoordinator.h"

extern NSString * const MADNotificationCloudActivityStarted;
extern NSString * const MADNotificationCloudActivityCompleted;

@interface MADCloudFileCoordinator : NSObject <MADFileCoordinator>

- (instancetype)initWithPredicate:(NSPredicate *)predicate identifier:(NSString *)identifier
          firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler;

- (instancetype)initWithPathExtension:(NSString *)pathExtension identifier:(NSString *)identifier
              firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler;

- (instancetype)initWithLastPathComponent:(NSString *)lastPathComponent identifier:(NSString *)identifier
                  firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler;

@end

#endif
