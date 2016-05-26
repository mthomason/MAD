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
    NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
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

- (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation {

    bool succes = true;
    for (NSObject <MADOperationCondition> *condition in self.conditions) {
        MADOperationConditionResult *result = [condition evaluateForOperation:operation];
        if (!result.isSucceed) {
            succes = false;
            break;
        }
    }
    
    MADOperationConditionResult *result;
    if (succes) {
    
        result = [MADOperationConditionResult newOperationConditionResultSatisfied];
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
