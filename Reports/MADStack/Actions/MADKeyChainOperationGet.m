//
//  MADKeyChainOperationGet.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/16/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADKeyChainOperationGet.h"
#import <MAD/MTKeyChain.h>
#import <Security/SecItem.h>
#import <CoreFoundation/CFData.h>
#import <Foundation/NSString.h>

@interface MADKeyChainOperationGet ()

    @property (nonatomic, readwrite, copy) NSString *key;
    @property (atomic, readwrite, copy) NSString *value;
    @property (atomic, readwrite, assign) bool success;

@end

@implementation MADKeyChainOperationGet

- (instancetype)initWithKey:(NSString *)key {
    if (self = [super init]) {
        self.key = key.copy;
        self.success = false;
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
 
    CFDataRef queryData = NULL;
    NSDictionary *queryDefination = [MTKeyChain queryDefination:self.key];
    OSStatus queryStatus = SecItemCopyMatching((__bridge CFDictionaryRef) queryDefination, (CFTypeRef *)&queryData);

    if (queryData == NULL) {
        [self finish];
        return;
    }
    
    NSString *result;
    
    switch (queryStatus) {
        case errSecSuccess:
            
            result = [[NSString alloc] initWithData: (__bridge_transfer NSData *) queryData encoding: NSUTF8StringEncoding];
            self.value = result;
            self.success = true;
            [self finish];
            break;
            
        default:
            self.value = nil;
            [self finish];
            break;
    }
}

@end
