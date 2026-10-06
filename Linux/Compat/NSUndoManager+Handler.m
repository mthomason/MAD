//
//  NSUndoManager+Handler.m
//  Linux/Compat
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//

#import "NSUndoManager+Handler.h"

#if !__APPLE__

@interface MADCompatUndoHandler : NSObject
@property (nonatomic, copy) void (^handler)(id);
- (void)invoke:(id)target;
@end

@implementation MADCompatUndoHandler

- (void)invoke:(id)target {
	if (self.handler != nil) {
		self.handler(target);
	}
}

@end

@implementation NSUndoManager (MADCompatHandler)

- (void)registerUndoWithTarget:(id)target handler:(void (^)(id target))handler {
	MADCompatUndoHandler *proxy = [[MADCompatUndoHandler alloc] init];
	proxy.handler = handler;
	[self registerUndoWithTarget:proxy selector:@selector(invoke:) object:target];
}

@end

#endif /* !__APPLE__ */
