//
//  MADOperationBooleanAnd.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/21/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationBooleanAnd.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import "MADOperationCondition.h"
#import "MADOperationConditionResult.h"
#import "NSError+MADOperationErrors.h"
#import <MAD/MADErrorUserInfo.h>

@interface MADOperationBooleanAnd ()

    @property (nonatomic, copy) NSArray <NSObject <MADOperationCondition> *> *conditions;

@end

@implementation MADOperationBooleanAnd

- (void)dealloc {
    NSLog(@"Operation deallocated. %s", __PRETTY_FUNCTION__);
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

- (void)evaluateForOperation:(MADOperation *)operation completion:(void(^)(MADOperationConditionResult *))completion {

    __block bool succes = true;
    for (NSObject <MADOperationCondition> *condition in self.conditions) {
        [condition evaluateForOperation:operation completion:^(MADOperationConditionResult *result) {
            if (!result.isSucceed) {
                succes = false;
            }
        }];
        if (!succes) {
            break;
        }
    }
    
    if (succes) {
        MADOperationConditionResult *result = [MADOperationConditionResult newOperationConditionResultSatisfied];
        completion(result);
    } else {
        MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:@"Not Satisified" andMessage:@"Not satisified."];
        NSError *error = [errorUserInfo errorWithDomain:self.name code:MADConditionFailed];
        MADOperationConditionResult *result = [MADOperationConditionResult newOperationConditionResultFailed:error];
        completion(result);
    }
}

@end
