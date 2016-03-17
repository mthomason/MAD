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
        MADOperation
        completion();
    } else {
        
    }
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

@end
