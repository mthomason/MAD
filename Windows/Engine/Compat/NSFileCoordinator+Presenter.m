//
//  NSFileCoordinator+Presenter.m
//  Linux/Compat
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "NSFileCoordinator+Presenter.h"

#if !__APPLE__

@implementation NSFileCoordinator (MADCompatPresenter)

// The warning that this shadows the primary class's implementation is the
// point: GNUstep's is the faulting one described in the header.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

- (instancetype)initWithFilePresenter:(id <NSFilePresenter>)filePresenterOrNil {
	(void)filePresenterOrNil;
	return [self init];
}

- (void)coordinateAccessWithIntents:(NSArray<NSFileAccessIntent *> *)intents
							  queue:(NSOperationQueue *)queue
						 byAccessor:(void (^)(NSError *))accessor {
	(void)intents;
	if (accessor == nil) return;
	if (queue != nil) {
		[queue addOperationWithBlock:^{ accessor(nil); }];
	} else {
		accessor(nil);
	}
}

#pragma clang diagnostic pop

@end

#endif /* !__APPLE__ */
