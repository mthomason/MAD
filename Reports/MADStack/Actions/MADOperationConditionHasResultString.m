//
//  MADOperationConditionHasCredientals.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationConditionHasResultString.h"
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import "MADOperationConditionHasResultStringResult.h"
#import "MADOperation.h"
#import "NSError+MADOperationErrors.h"
#import "MADOperationKeyChainGet.h"
#import "MADOperationConditionResult.h"
#import <MAD/MADErrorUserInfo.h>

#import <os/log.h>

@interface MADOperationConditionHasResultString ()

    @property (nonatomic, readwrite, copy) NSString *key;

@end

@implementation MADOperationConditionHasResultString

- (void)dealloc {
    os_log_info(OS_LOG_DEFAULT, "Dealloc %s", NSStringFromClass(self.class).UTF8String);
}

- (instancetype)initWithKey:(NSString *)key {
    if (self = [super init]) {
        _key = key.copy;
    }
    return self;
}

#pragma mark - Condition
- (NSString *)name {
    return NSStringFromClass(self.class);
}

- (BOOL)isMutuallyExclusive {
    return NO;
}

- (NSOperation *)dependencyForOperation:(MADOperation *)operation {
    return nil;
}

- (void)evaluateForOperation:(MADOperation *)operation completion:(void (^)(MADOperationConditionResult *))completion {
    MADOperationConditionResult *result;
    result = [self evaluateForOperation:operation];
    completion(result);
}

- (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation {
    os_log_info(OS_LOG_DEFAULT, "Dealloc %s", operation.description.UTF8String);

    NSArray<__kindof NSOperation *> *dependencies = operation.dependencies;
    MADOperationConditionResult *result = nil;
    if (dependencies.count == 0) {
        MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:@"Not Satisified"
                                                                       andMessage:@"Not satisified."];
        NSError *error = [errorUserInfo errorWithDomain:self.name code:MADConditionFailed];
        result = [MADOperationConditionResult newOperationConditionResultFailed:error];
        return result;
    }
    
    for (NSOperation *dependency in dependencies) {
    
        if ([dependency conformsToProtocol:@protocol(MADOperationResultStringProtocol)] &&
            [self.key isEqualToString: ((NSObject <MADOperationResultStringProtocol> *) dependency).key]) {
            
            if (((NSObject <MADOperationResultStringProtocol> *) dependency).success) {
                
                result = [MADOperationConditionHasResultStringResult newOperationConditionResultSatisfied];
                
                ((MADOperationConditionHasResultStringResult *)result).result = ((NSObject <MADOperationResultStringProtocol> *) dependency).value;
                
            } else {
                MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:@"Not Satisified"
                                                                               andMessage:@"Not satisified."];
                NSError *error = [errorUserInfo errorWithDomain:self.name code:MADConditionFailed];
                result = [MADOperationConditionResult newOperationConditionResultFailed:error];
            }
            break;
        }
    }
    
    if (result != nil) {
        return result;
    } else {
        MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:@"Not Satisified"
                                                                       andMessage:@"Not satisified."];
        NSError *error = [errorUserInfo errorWithDomain:self.name code:MADConditionFailed];
        result = [MADOperationConditionResult newOperationConditionResultFailed:error];
        return result;
    }
    
}

@end
