//
//  MADCloudFileCoordinator.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADDesigner_MADCloudFileCoordinator_h
#define MADDesigner_MADCloudFileCoordinator_h

#import <Foundation/NSObject.h>
#import "MADFileCoordinator.h"

extern NSString * const MADNotificationCloudActivityStarted;
extern NSString * const MADNotificationCloudActivityCompleted;

@class NSPredicate;

@interface MADCloudFileCoordinator : NSObject <MADFileCoordinatorProtocol>

	- (instancetype)initWithPredicate:(NSPredicate *)predicate
						   identifier:(NSString *)identifier
			  firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler;

	- (instancetype)initWithPathExtension:(NSString *)pathExtension
							   identifier:(NSString *)identifier
				  firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler;

	- (instancetype)initWithLastPathComponent:(NSString *)lastPathComponent
								   identifier:(NSString *)identifier
					  firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler;

@end

#endif
