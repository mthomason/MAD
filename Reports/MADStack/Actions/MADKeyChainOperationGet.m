//
//  MADKeyChainOperationGet.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/16/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADKeyChainOperationGet.h"
#import <MAD/MTKeyChain.h>
#import <Security/SecItem.h>
#import <CoreFoundation/CFData.h>
#import <Foundation/NSString.h>
#import <Foundation/NSError.h>

@interface MADKeyChainOperationGet ()

    @property (nonatomic, readwrite, copy) NSString *key;
    @property (nonatomic, readwrite, copy) NSString *keyDescription;
    @property (atomic, readwrite, copy) NSString *value;
    @property (atomic, readwrite, assign) BOOL success;

@end

@implementation MADKeyChainOperationGet

- (void)dealloc {
    //NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
}

- (instancetype)initWithKey:(NSString *)key withDescription:(NSString *)description {
    if (self = [super init]) {
        //NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
        _key = key.copy;
        _success = NO;
        _keyDescription = description.copy;
    }
    return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {

    //NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);

    CFDataRef queryData = NULL;
    NSDictionary *queryDefination = [MTKeyChain queryDefination:self.key withDescription:self.keyDescription];
    CFDictionaryRef queryDefinationC = (__bridge_retained CFDictionaryRef)queryDefination;
    OSStatus queryStatus = SecItemCopyMatching(queryDefinationC, (CFTypeRef *)&queryData);
    CFRelease(queryDefinationC);
    
    if (queryData == NULL) {
        NSString *domain = NSStringFromClass([self class]);
        NSError *error = [NSError errorWithDomain:domain code:queryStatus userInfo:nil];
        [self finishWithError:error];
        return;

    }
    NSData *resultData = (__bridge_transfer NSData *)queryData;

    NSString *result;
    
    switch (queryStatus) {
        case errSecSuccess:
            
            result = [[NSString alloc] initWithData: resultData encoding: NSUTF8StringEncoding];
            self.value = result;
            self.success = YES;
            [self finish];
            break;
            
        default:

            self.value = nil;
            break;
    }
    if (self.success) {
        [self finish];
    } else {
        NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:queryStatus userInfo:nil];
        [self finishWithError:error];
    }
}

@end
