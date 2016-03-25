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
#import "MADOperationConditionResult.h"
#import "NSError+MADOperationErrors.h"
#import <MAD/MADErrorUserInfo.h>

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
        MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:@"Not Satisified" andMessage:@"Not satisified."];
        NSError *error = [NSError errorWithDomain:self.name code:MADConditionFailed userInfo:errorUserInfo.userinfo];
        completion([MADOperationConditionResult failed:error]);
        return;
    }

    MADOperationConditionResult *result = nil;
    
    for (NSOperation *dependency in dependencies) {
        if ([dependency conformsToProtocol:@protocol(MADOperationConditionPolarQuestionResultProtocol)] &&
            dependency.hash == self.tag) {
            
            if (((NSObject <MADOperationConditionPolarQuestionResultProtocol> *)dependency).result) {

                result = [MADOperationConditionResult satisfied];
                
            } else {
                MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:@"Not Satisified" andMessage:@"Not satisified."];
                NSError *error = [NSError errorWithDomain:self.name code:MADConditionFailed userInfo:errorUserInfo.userinfo];
                result = [MADOperationConditionResult failed:error];
                
            }
            break;
        }
    }

    if (result != nil) {
        completion(result);
    } else {
        MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:@"Not Satisified" andMessage:@"Not satisified."];
        NSError *error = [NSError errorWithDomain:self.name code:MADConditionFailed userInfo:errorUserInfo.userinfo];
        completion([MADOperationConditionResult failed:error]);
    }

}

@end
