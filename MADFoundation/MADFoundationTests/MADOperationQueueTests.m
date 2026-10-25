//
//  MADOperationQueueTests.m
//  MADFoundationTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for MADOperationQueue: the delegate callbacks for both MADOperation
//  and plain NSOperation instances.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADOperationQueue.h>
#import <MADFoundation/MADOperation.h>

@interface MADQueueRunOperation : MADOperation
@end
@implementation MADQueueRunOperation
- (void)beginBackgroundTask {}
- (void)endBackgroundTask {}
- (void)execute { [self finish]; }
@end

@interface MADOperationQueueTests : XCTestCase <MADOperationQueueDelegate>
@property (nonatomic, assign) BOOL willAddCalled;
@property (nonatomic, assign) BOOL didFinishCalled;
@end

@implementation MADOperationQueueTests

- (void)operationQueue:(MADOperationQueue *)operationQueue willAddOperation:(NSOperation *)operation {
	self.willAddCalled = YES;
}

- (void)operationQueue:(MADOperationQueue *)operationQueue operationDidFinish:(NSOperation *)operation withErrors:(NSArray<NSError *> *)errors {
	self.didFinishCalled = YES;
}

- (void)testAddMADOperationNotifiesDelegate {
	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	queue.delegate = self;
	self.willAddCalled = NO;
	self.didFinishCalled = NO;

	MADQueueRunOperation *op = [[MADQueueRunOperation alloc] init];
	[queue addOperation:op];

	XCTAssertTrue(self.willAddCalled);

	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:5.0];
	while (!self.didFinishCalled && [deadline timeIntervalSinceNow] > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
	}
	XCTAssertTrue(self.didFinishCalled);
}

- (void)testAddStandardOperationNotifiesDelegate {
	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	queue.delegate = self;
	self.didFinishCalled = NO;

	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{}];
	[queue addOperation:op];

	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:5.0];
	while (!self.didFinishCalled && [deadline timeIntervalSinceNow] > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
	}
	XCTAssertTrue(self.didFinishCalled);
}

@end
