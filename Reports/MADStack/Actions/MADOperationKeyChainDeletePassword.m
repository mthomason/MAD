//
//  MADOperationKeyChainDeletePassword.m
//  MAD Designer
//
//  Created by Michael on 8/12/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationKeyChainDeletePassword.h"
#import <Foundation/NSString.h>
#import <MAD/MTKeyChain.h>

@interface MADOperationKeyChainDeletePassword ()

    @property (nonatomic, readwrite, copy) NSString *key;
    @property (atomic, readwrite, assign) BOOL success;

@end

@implementation MADOperationKeyChainDeletePassword

- (void)dealloc {
    //NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
}

- (instancetype)initWithKey:(NSString *)key {
    if (self = [super init]) {
        //NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
        _key = key.copy;
        _success = NO;
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    NSAssert(_key != nil, @"Need a key.");
    NSError * __autoreleasing error = nil;
    [MTKeyChain deleteSavedPasswordForKey: _key error: &error];
    if (error != nil) {
        [self finishWithError:error];
    } else {
        [self finish];
    }
}

@end
