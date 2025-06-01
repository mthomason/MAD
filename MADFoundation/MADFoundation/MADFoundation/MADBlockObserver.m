//
//  MADBlockObserver.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#import "MADBlockObserver.h"
#import "madlog.h"

@interface MADBlockObserver ()

	@property (nonatomic, copy, nullable) void(^startHandler)(MADOperation *);
	@property (nonatomic, copy, nullable) void(^produceHandler)(MADOperation *, NSOperation *);
	@property (nonatomic, copy, nullable) void(^finishHandler)(MADOperation *, NSArray <NSError *> *);

@end

@implementation MADBlockObserver

- (instancetype)initWithStartHandler:(void(^)(MADOperation *))startHandler
					  produceHandler:(void(^)(MADOperation *, NSOperation *))produceHandler
					   finishHandler:(void(^)(MADOperation *, NSArray <NSError *> *))finishHandler {
	if (self = [super init]){
		self.startHandler = startHandler;
		self.produceHandler = produceHandler;
		self.finishHandler = finishHandler;
	}
	return self;
}

- (instancetype)initWithFinishHandler:(nullable void(^)(MADOperation *, NSArray<NSError *> *))finishHandler {
	return [self initWithStartHandler:nil produceHandler:nil finishHandler:finishHandler];
}

#pragma mark - OperationObserver protocol

- (void)operationDidStart:(nonnull MADOperation *)operation {
	MADLogDebug("MADBlockObserver <%p> operationDidStart: %@. (Handler %s)", self, operation, self.startHandler ? "exists" : "nil");
	if (self.startHandler) {
		self.startHandler(operation);
	}
}

-(void)operation:(nonnull MADOperation *)operation didProduceOperation:(nonnull NSOperation *)newOperation {
	MADLogDebug("MADBlockObserver <%p> operation: %@ didProduceOperation: %@. (Handler %s)", self, operation, newOperation, self.produceHandler ? "exists" : "nil");
	if (self.produceHandler) {
		self.produceHandler(operation, newOperation);
	}
}

-(void)operationDidFinish:(nonnull MADOperation *)operation
				   errors:(nullable NSArray <NSError *> *)errors {
	MADLogDebug("MADBlockObserver <%p> operationDidFinish: %@, Errors: %@ (Count: %lu). (Handler %s)",
				self, operation, errors, (unsigned long)(errors ? errors.count : 0), self.finishHandler ? "exists" : "nil");
	if (self.finishHandler) {
		self.finishHandler(operation, errors);
	}
}

@end
