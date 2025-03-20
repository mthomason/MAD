//
//  MADBlockObserver.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBlockObserver.h"

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
	if (self.startHandler) {
		__weak typeof(self) weakSelf = self;
		self.startHandler(operation);
	}
}

-(void)operation:(nonnull MADOperation *)operation
	didProduceOperation:(nonnull NSOperation *)newOperation {
	if (self.produceHandler) {
		__weak typeof(self) weakSelf = self;
		self.produceHandler(operation, newOperation);
	}
}

-(void)operationDidFinish:(nonnull MADOperation *)operation
				   errors:(nullable NSArray <NSError *> *)errors {
	if (self.finishHandler) {
		__weak typeof(self) weakSelf = self;
		self.finishHandler(operation, errors);
	}
}

@end
