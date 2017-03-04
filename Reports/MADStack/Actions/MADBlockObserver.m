//
//  MADBlockObserver.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADBlockObserver.h"

@interface MADBlockObserver ()

    @property (nonatomic, copy) void(^startHandler)(MADOperation *);
    @property (nonatomic, copy) void(^produceHandler)(MADOperation *, NSOperation *);
    @property (nonatomic, copy) void(^finishHandler)(MADOperation *, NSArray *);

@end

@implementation MADBlockObserver

- (instancetype)initWithStartHandler:(void(^)(MADOperation *))startHandler
                      produceHandler:(void(^)(MADOperation *, NSOperation *))produceHandler
                       finishHandler:(void(^)(MADOperation *, NSArray *))finishHandler {
    if (self = [super init]){
        self.startHandler = startHandler;
        self.produceHandler = produceHandler;
        self.finishHandler = finishHandler;
    }
    return self;
}

#pragma mark - OperationObserver protocol

- (void)operationDidStart:(MADOperation *)operation {
    if (_startHandler){
        _startHandler(operation);
    }
}

-(void)operation:(MADOperation *)operation didProduceOperation:(NSOperation *)newOperation {
    if (_produceHandler){
        _produceHandler(operation, newOperation);
    }
}

-(void)operationDidFinish:(MADOperation *)operation errors:(NSArray *)errors {
    if (_finishHandler){
        _finishHandler(operation, errors);
    }
}

@end
