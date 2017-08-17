//
//  MADOperationConditionHasCredientals.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationConditionMissingResultString.h"

#import <os/log.h>

#import <Foundation/NSOperation.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>

#import <MADFoundation/MADErrorUserInfo.h>
#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationConditionResult.h>
#import <MADFoundation/NSError+MADOperationErrors.h>

#import "MADOperationConditionHasResultStringResult.h"
#import "MADOperationKeyChainGet.h"

@interface MADOperationConditionMissingResultString ()

    @property (nonatomic, readwrite, copy) NSString *key;

@end

@implementation MADOperationConditionMissingResultString

- (void)dealloc {
    os_log_info(OS_LOG_DEFAULT, "Dealloc %s", __PRETTY_FUNCTION__);
}

- (instancetype)initWithKey:(NSString *)key {
    if (self = [super init]) {
        self.key = key.copy;
    }
    return self;
}

#pragma mark - Condition

- (NSString *)name { return NSStringFromClass(self.class); }

- (BOOL)isMutuallyExclusive { return NO; }

- (NSOperation *)dependencyForOperation:(MADOperation *)operation { return nil; }

- (void)evaluateForOperation:(MADOperation *)operation completion:(void (^)(MADOperationConditionResult *))completion {
    MADOperationConditionResult *result;
    result = [self evaluateForOperation:operation];
    completion(result);
}

- (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation {
    os_log_info(OS_LOG_DEFAULT, "Evaluate %s", operation.description.UTF8String);

    MADOperationConditionResult *result = nil;
    NSString *kNotSatisified = @"Not Satisified";
    NSArray <__kindof NSOperation *> *dependencies = operation.dependencies;
    if (dependencies.count == 0) {
        result = [MADOperationConditionResult newOperationConditionResultFailedNotSatisfied:self.name];
        return result;
    }
    
    for (NSOperation *dependency in dependencies) {
        if ([dependency conformsToProtocol:@protocol(MADOperationResultStringProtocol)] &&
            [self.key isEqualToString: ((NSObject <MADOperationResultStringProtocol> *) dependency).key]) {
            if(!((NSObject <MADOperationResultStringProtocol> *) dependency).success) {
                result = [MADOperationConditionHasResultStringResult newOperationCondition: (NSObject <MADOperationResultStringProtocol> *)dependency
                                                                                      name: self.name];
                break;
            }
        }
    }
    
    if (result != nil) {
        return result;
    } else {
        MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:kNotSatisified
                                                                       andMessage:kNotSatisified];
        NSError *error = [errorUserInfo errorWithDomain:self.name code:MADConditionFailed];
        result = [MADOperationConditionResult newOperationConditionResultFailed:error];
        return result;
    }
    
}

@end
