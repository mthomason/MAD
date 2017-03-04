//
//  MADKeyChainOperationPut.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADKeyChainOperationPut.h"
#import <security/SecBase.h>
#import <Foundation/NSString.h>
#import <Foundation/NSError.h>
#import <Foundation/NSArray.h>
#import <MAD/MTKeyChain.h>
#import <MAD/MADCredential.h>

static const short StatusNotFound = 35;
static NSString * const ErrorDomain = @"MADKCP";

@interface MADKeyChainOperationPut ()

    @property (nonatomic, copy) NSString *key;
    @property (nonatomic, copy) NSString *keyDescription;

@end

@implementation MADKeyChainOperationPut

- (void)dealloc {
    //NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
}

- (instancetype)initWithKey:(NSString *)key description:(NSString *)description {
    if (self = [super init]) {
        //NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
        _key = key.copy;
        _keyDescription = description.copy;
    }
    return self;
}

- (void)execute {
    //NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);

    NSString *valueToWrite = nil;
    
    // Search the operations dependencies for the value to write.
    //
    NSArray<__kindof NSOperation *> *dependencies = self.dependencies;
    for (NSOperation *operation in dependencies) {
    
        if ([operation conformsToProtocol:@protocol(MADKeyChainKeyValueProtocol)]) {
            valueToWrite = [((NSObject <MADKeyChainKeyValueProtocol> *)operation) valueForKey:self.key];
            if (valueToWrite != nil) {
                break;
            }
        }
        
    }

    // Write the value to the keychain.
    if (valueToWrite != nil) {
    
        OSStatus status = [MTKeyChain saveToken:valueToWrite forKey:self.key withDescription:self.keyDescription];
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
