//
//  MADOperationKeyChainPut.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationKeyChainPut.h"
#import <security/SecBase.h>
#import <Foundation/NSString.h>
#import <Foundation/NSError.h>
#import <Foundation/NSArray.h>
#import <MAD/MTKeyChain.h>
#import <MAD/MADCredential.h>

#import <os/log.h>

static const short StatusNotFound = 35;
static NSString * const ErrorDomain = @"MADKCP";

@interface MADOperationKeyChainPut ()

    @property (nonatomic, copy) NSString *key;
    @property (nonatomic, copy) NSString *keyDescription;

@end

@implementation MADOperationKeyChainPut

- (void)dealloc {
    os_log_info(OS_LOG_DEFAULT, "Dealloc %s", NSStringFromClass(self.class).UTF8String);
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
    os_log_info(OS_LOG_DEFAULT, "Begin %s", NSStringFromClass(self.class).UTF8String);

    if (self.cancelled) return [self finish];

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
    
    if (self.cancelled) return [self finish];

    // Write the value to the keychain.
    if (valueToWrite != nil) {
    
        OSStatus status = [MTKeyChain saveToken: valueToWrite
                                         forKey: self.key
                                withDescription: self.keyDescription];
        if (status == errSecSuccess) {
        
            os_log_info(OS_LOG_DEFAULT, "%s\t%s", "Finish success:", __PRETTY_FUNCTION__);
            [self finish];

        } else {


            os_log_info(OS_LOG_DEFAULT, "%s\t%s", "Finish error:", __PRETTY_FUNCTION__);
            NSError *error = [NSError errorWithDomain:ErrorDomain code:status userInfo:nil];
            [self finishWithError:error];
            
        }
        
    } else {

        os_log_info(OS_LOG_DEFAULT, "%s\t%s", "Finish error:", __PRETTY_FUNCTION__);
        NSError *error = [NSError errorWithDomain:ErrorDomain code:StatusNotFound userInfo:nil];
        [self finishWithError:error];
        
    }
}

@end
