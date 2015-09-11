//
//  MADOperationArchiveData.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationArchiveData.h"

@interface MADOperationArchiveData ()
    @property (nonatomic, strong) NSURL *url;
    @property (nonatomic, strong) id <NSCoding> object;
    @property (nonatomic, assign) BOOL isOperationExecuting;
    @property (nonatomic, assign) BOOL isOperationFinished;
@end

@implementation MADOperationArchiveData

- (void)setIsOperationExecuting:(BOOL)isExecuting {
    [self willChangeValueForKey:@"isExecuting"];
    _isOperationExecuting = isExecuting;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)setIsOperationFinished:(BOOL)isFinished {
    [self willChangeValueForKey:@"isFinished"];
    _isOperationFinished = isFinished;
    [self didChangeValueForKey:@"isFinished"];
}

- (instancetype)initWithURL:(NSURL *)url andObject:(id <NSCoding>)object {
    if (self = [super init]) {
        self.url = url;
        self.object = object;
    }
    return self;
}

- (void)start {
    [self setIsOperationExecuting: YES];
    [self setIsOperationFinished: NO];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error = nil;
        NSData *d = [NSKeyedArchiver archivedDataWithRootObject:self.object];
        [d writeToURL:self.url options:NSDataWritingAtomic error:&error];
        [self setIsOperationExecuting: NO];
        [self setIsOperationFinished: YES];
    });
}

- (BOOL)asynchronous {
    return YES;
}

- (BOOL)isExecuting {
    return self.isOperationExecuting;
}

- (BOOL)isFinished {
    return self.isOperationFinished;
}

@end
