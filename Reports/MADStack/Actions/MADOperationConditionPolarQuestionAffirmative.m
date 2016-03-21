//
//  MADOperationConditionPolarQuestionAffirmative.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationConditionPolarQuestionAffirmative.h"
#import <Foundation/NSObject.h>
#import "MADPromptOperationPolarQuestion.h"
#import "MADOperationConditionPolarQuestionAffirmativeResult.h"

@interface MADOperationConditionPolarQuestionAffirmative ()

    @property (nonatomic, readwrite) NSUInteger tag;

@end

@implementation MADOperationConditionPolarQuestionAffirmative

- (instancetype)initWithTag:(NSUInteger)tag {
    if (self = [super init]) {
        _tag = tag;
    }
    return self;
}

#pragma mark - Condition

- (NSString *)name { return NSStringFromClass(self.class); }

- (BOOL)isMutuallyExclusive { return NO; }

- (NSOperation *)dependencyForOperation:(MADOperation *)operation { return nil; }

- (void)evaluateForOperation:(MADOperation *)operation
                  completion:(void (^)(MADOperationConditionResult *))completion {
    

    if ([operation conformsToProtocol:@protocol(MADOperationConditionPolarQuestionResultProtocol)]) {
        
        if (((NSObject <MADOperationConditionPolarQuestionResultProtocol> *)operation).result &&
                operation.hash == self.tag) {

            MADOperationConditionPolarQuestionAffirmativeResult *result = [MADOperationConditionPolarQuestionAffirmativeResult satisfied];
            result.result = true;
            completion(result);

        } else {

            MADOperationConditionPolarQuestionAffirmativeResult *result = [MADOperationConditionPolarQuestionAffirmativeResult failed:nil];
            result.result = false;
            completion(result);

        }
    } else {
        completion([MADOperationConditionResult failed:nil]);
    }
}

@end
