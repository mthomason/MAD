//
//  MADOperationBooleanAnd.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/21/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADOperationBooleanAnd.h"
#import <os/log.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>

#import <MADFoundation/MADErrorUserInfo.h>
#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationCondition.h>
#import <MADFoundation/MADOperationConditionResult.h>
#import <MADFoundation/NSError+MADOperationErrors.h>

@interface MADOperationBooleanAnd ()

    @property (nonatomic, copy) NSArray <NSObject <MADOperationCondition> *> *conditions;

@end

@implementation MADOperationBooleanAnd

- (void)dealloc {
    ////os_log_info(OS_LOG_DEFAULT, "Dealloc %s", NSStringFromClass(self.class).UTF8String);
}

- (instancetype)initWithConditions:(NSArray <NSObject <MADOperationCondition> *> *)conditions {
    if (self = [super init]) {
        _conditions = conditions.copy;
    }
    return self;
}

- (NSString *)name { return NSStringFromClass(self.class); }

- (BOOL)isMutuallyExclusive { return NO; }

- (NSOperation *)dependencyForOperation:(MADOperation *)operation { return nil; }

- (void)evaluateForOperation:(MADOperation *)operation completion:(void (^)(MADOperationConditionResult *))completion {
    MADOperationConditionResult *result;
    result = [self evaluateForOperation:operation];
    completion(result);
}

- (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation {
    os_log_info(OS_LOG_DEFAULT, "%s\t%s", "Evaluate", operation.description.UTF8String);

    BOOL succes = YES;
    for (NSObject <MADOperationCondition> *condition in self.conditions) {
        MADOperationConditionResult *result = [condition evaluateForOperation:operation];
        if (!result.isSucceed) {
            succes = NO;
            break;
        }
    }
    return [MADOperationConditionResult newOperationConditionResult: succes
                                                               name: self.name];
}

@end
