//
//  MADOperationKeyChainDeletePassword.m
//  MAD Designer
//
//  Created by Michael on 8/12/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADOperationKeyChainDeletePassword.h"
#import <os/log.h>
#import <Foundation/NSString.h>
#import <MADFoundation/MADKeyChain.h>

@interface MADOperationKeyChainDeletePassword ()

    @property (nonatomic, readwrite, copy) NSString *key;
    @property (atomic, readwrite, assign) BOOL success;

@end

@implementation MADOperationKeyChainDeletePassword

- (void)dealloc {
    //os_log_info(OS_LOG_DEFAULT, "Dealloc %s", NSStringFromClass(self.class).UTF8String);
}

- (instancetype)initWithKey:(NSString *)key {
    if (self = [super init]) {
        _key = key.copy;
        _success = NO;
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
    //os_log_info(OS_LOG_DEFAULT, "Begin %s", NSStringFromClass(self.class).UTF8String);

    if (self.cancelled) {
        return [self finish];
    }

    NSAssert(_key != nil, @"Need a key.");
    NSError * __autoreleasing error = nil;
    [MADKeyChain deleteSavedPasswordForKey: _key error: &error];
    if (error != nil) {
        [self finishWithError:error];
    } else {
        [self finish];
    }
}

@end
