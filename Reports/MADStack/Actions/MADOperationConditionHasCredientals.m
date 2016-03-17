//
//  MADOperationConditionHasCredientals.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/17/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationConditionHasCredientals.h"
#import "MADOperation.h"
#import "NSError+MADOperationErrors.h"
#import <Foundation/NSDictionary.h>

@implementation MADOperationConditionHasCredientals

#pragma mark - Condition
- (NSString *)name {
    return NSStringFromClass(self.class);
}

- (BOOL)isMutuallyExclusive {
    return NO;
}

- (void)evaluateForOperation:(MADOperation *)operation
                 completion:(void (^)(MADOperationConditionResult *))completion {
     // Since evaluation requires executing an operation, use a private operation queue.
        if (YES){
            completion([MADOperationConditionResult satisfied]);
        } else {
            completion([MADOperationConditionResult failed:[NSError errorWithCode: 333
                                                                         userInfo: @{
                                                                                     MADOperationConditionKey: self.name,
                                                                                     NSUnderlyingErrorKey: @""
                                                                                     }]]
                       );
        }
}

- (NSOperation *)dependencyForOperation:(MADOperation *)operation {
    return nil;
}

@end
