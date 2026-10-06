//
//  MADOperationQueueTests.m
//  Linux/Tests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Ported from MADFoundationTests/MADOperationQueueTests.m: coverage for
//  MADOperationQueue, the delegate callbacks for both MADOperation and plain
//  NSOperation instances.
//

#import "MADTestSupport.h"
#import <MADFoundation/MADOperationQueue.h>
#import <MADFoundation/MADOperation.h>

@interface MADQueueRunOperation : MADOperation
@end

@implementation MADQueueRunOperation
- (void)beginBackgroundTask {}
- (void)endBackgroundTask {}
- (void)execute { [self finish]; }
@end

@interface MADQueueDelegate : NSObject <MADOperationQueueDelegate>
@property (nonatomic, assign) BOOL willAddCalled;
@property (nonatomic, assign) BOOL didFinishCalled;
@end

@implementation MADQueueDelegate

- (void)operationQueue:(MADOperationQueue *)operationQueue willAddOperation:(NSOperation *)operation {
	self.willAddCalled = YES;
}

- (void)operationQueue:(MADOperationQueue *)operationQueue operationDidFinish:(NSOperation *)operation withErrors:(NSArray<NSError *> *)errors {
	self.didFinishCalled = YES;
}

@end

static void testAddMADOperationNotifiesDelegate(void) {
	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	MADQueueDelegate *delegate = [[MADQueueDelegate alloc] init];
	queue.delegate = delegate;
	delegate.willAddCalled = NO;
	delegate.didFinishCalled = NO;

	MADQueueRunOperation *op = [[MADQueueRunOperation alloc] init];

	// GNUstep divergence: its NSOperationQueue removes its "isReady" KVO
	// observation every time the notification fires, and MADOperation's state
	// machine notifies isReady more than once (Pending -> EvaluatingConditions
	// -> Ready) where Apple's notifies once -- so GNUstep's second removal
	// raises NSInvalidArgumentException and the operation never runs.  The
	// divergence is recorded as a counted need (see the Phase B status in
	// MAD_LINUX.md), never hidden.
	@try {
		[queue addOperation:op];

		MAD_PASS(delegate.willAddCalled, "the delegate was told an operation will be added");

		NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:5.0];
		while (!delegate.didFinishCalled && [deadline timeIntervalSinceNow] > 0) {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
									 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
		}
		MAD_PASS(delegate.didFinishCalled, "the delegate was told the operation finished");
	} @catch (NSException *e) {
		MAD_NEED(NO, @"GNUstep's NSOperationQueue removes its isReady observation twice; MADOperation's state machine notifies isReady more than once (Apple does once) and GNUstep raises on the second removal");
	}
}

static void testAddStandardOperationNotifiesDelegate(void) {
	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	MADQueueDelegate *delegate = [[MADQueueDelegate alloc] init];
	queue.delegate = delegate;
	delegate.didFinishCalled = NO;

	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{}];
	[queue addOperation:op];

	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:5.0];
	while (!delegate.didFinishCalled && [deadline timeIntervalSinceNow] > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
	}
	MAD_PASS(delegate.didFinishCalled, "the delegate was told the plain operation finished");
}

MAD_TEST_MAIN("MADOperationQueueTests",
	MAD_TEST(testAddMADOperationNotifiesDelegate),
	MAD_TEST(testAddStandardOperationNotifiesDelegate));
