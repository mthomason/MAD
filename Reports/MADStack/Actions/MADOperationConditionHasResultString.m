//
//  MADOperationConditionHasCredientals.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationConditionHasResultString.h"
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import "MADOperationConditionHasResultStringResult.h"
#import "MADOperation.h"
#import "NSError+MADOperationErrors.h"
#import "MADKeyChainOperationGet.h"

@implementation MADOperationConditionHasResultString

- (instancetype)initWithKey:(NSString *)key {
    if (self = [super init]) {
        self.key = key;
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

- (void)evaluateForOperation:(MADOperation *)operation
                  completion:(void (^)(MADOperationConditionResult *))completion {
    
    if ([operation conformsToProtocol:@protocol(MADOperationResultStringProtocol)]) {
        
        if ([self.key isEqualToString: ((NSObject <MADOperationResultStringProtocol> *) operation).key]) {
        
            MADOperationConditionHasResultStringResult *result = [MADOperationConditionHasResultStringResult satisfied];
            result.result = ((NSObject <MADOperationResultStringProtocol> *) operation).result;
            completion(result);
        
        } else {
            completion([MADOperationConditionResult failed:nil]);
        }
        
    } else {
        completion([MADOperationConditionResult failed:nil]);
    }
}

@end
