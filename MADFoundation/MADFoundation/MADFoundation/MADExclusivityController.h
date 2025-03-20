//
//  MADExclusivityController.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADExclusivityController_h
#define MAD_Designer_MADExclusivityController_h

#import <Foundation/Foundation.h>

@class MADOperation;

/**
	`ExclusivityController` is a singleton to keep track of all the in-flight
	`Operation` instances that have declared themselves as requiring mutual exclusivity.
	We use a singleton because mutual exclusivity must be enforced across the entire
	app, regardless of the `OperationQueue` on which an `Operation` was executed.
 */

@interface MADExclusivityController : NSObject
	+ (nonnull instancetype)sharedExclusivityController;

	- (void)addOperation:(nonnull MADOperation *)operation
			  categories:(nonnull NSArray<NSString *> *)categories;
	- (void)removeOperation:(nonnull MADOperation *)operation
				 categories:(nonnull NSArray<NSString *> *)categories;
@end

#endif
