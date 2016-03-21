//
//  MADOperationConditionPolarQuestionAffirmative.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationConditionPolarQuestionAffirmative.h"
#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
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
    
    NSArray<__kindof NSOperation *> *dependencies = operation.dependencies;
    if (dependencies.count == 0) {
        completion([MADOperationConditionResult failed:nil]);
        return;
    }

    MADOperationConditionResult *result = nil;
    
    for (NSOperation *dependency in dependencies) {
        if ([dependency conformsToProtocol:@protocol(MADOperationConditionPolarQuestionResultProtocol)] &&
            dependency.hash == self.tag) {
            
            if (((NSObject <MADOperationConditionPolarQuestionResultProtocol> *)dependency).result) {
                
                result = [MADOperationConditionPolarQuestionAffirmativeResult satisfied];
                ((MADOperationConditionPolarQuestionAffirmativeResult *)result).result = true;
            } else {
                result = [MADOperationConditionResult failed:nil];
            }
            break;
        }
    }

    if (result != nil) {
        completion(result);
    } else {
        completion([MADOperationConditionResult failed:nil]);
    }

}

@end
