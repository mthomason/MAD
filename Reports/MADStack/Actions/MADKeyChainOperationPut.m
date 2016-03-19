//
//  MADKeyChainOperationPut.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADKeyChainOperationPut.h"
#import <security/SecBase.h>
#import <Foundation/NSString.h>
#import <Foundation/NSError.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <MAD/MTKeyChain.h>

static const short StatusNotFound = 35;
static NSString * const ErrorDomain = @"MADKCP";

@interface MADKeyChainOperationPut ()

    @property (nonatomic, copy) NSString *key;

@end

@implementation MADKeyChainOperationPut

- (instancetype)initWithKey:(NSString *)key {
    if (self = [super init]) {
        _key = key.copy;
    }
    return self;
}

- (void)execute {

    NSString *valueToWrite = nil;
    for (NSOperation *operation in self.dependencies) {
        if ([operation conformsToProtocol:@protocol(MADKeyChainKeyValueProtocol)]) {
            NSString *key = [((NSObject <MADKeyChainKeyValueProtocol> *)operation) key];
            if ([key isEqualToString:self.key]) {
                NSString *value = [((NSObject <MADKeyChainKeyValueProtocol> *)operation) value];
                if (value != nil) {
                    valueToWrite = [NSString stringWithString:value];
                    break;
                }
            }
        }
    }

    if (valueToWrite != nil) {
        OSStatus status = [MTKeyChain saveToken:valueToWrite forKey:self.key];
        if (status == errSecSuccess) {
            [self finish];
        } else {
            NSError *error = [NSError errorWithDomain:ErrorDomain code:status userInfo:nil];
            [self finishWithError:error];
        }
    } else {
        NSError *error = [NSError errorWithDomain:ErrorDomain code:StatusNotFound userInfo:nil];
        [self finishWithError:error];
    }
}

@end
