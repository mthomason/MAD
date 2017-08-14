//
//  MADOperationConditionPolarQuestionAffirmative.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationConditionPolarQuestionAffirmative.h"
#import <asl.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import "MADPromptOperationPolarQuestion.h"
#import "MADOperationConditionPolarQuestionAffirmativeResult.h"
#import "MADOperationConditionResult.h"
#import "NSError+MADOperationErrors.h"
#import <MAD/MADErrorUserInfo.h>

#import <os/log.h>

@interface MADOperationConditionPolarQuestionAffirmative ()

    @property (nonatomic, readwrite) NSUInteger tag;

@end

@implementation MADOperationConditionPolarQuestionAffirmative

- (void)dealloc {
    os_log_info(OS_LOG_DEFAULT, "%s", __PRETTY_FUNCTION__);
}

- (instancetype)initWithOperationIdentifier:(NSUInteger)tag {
    if (self = [super init]) {
        _tag = tag;
    }
    return self;
}

#pragma mark - Condition

- (NSString *)name { return NSStringFromClass(self.class); }

- (BOOL)isMutuallyExclusive { return NO; }

- (NSOperation *)dependencyForOperation:(MADOperation *)operation { return nil; }

- (void)evaluateForOperation:(MADOperation *)operation completion:(void (^)(MADOperationConditionResult *))completion {
    os_log_info(OS_LOG_DEFAULT, "%s\t%s", __PRETTY_FUNCTION__, operation.description.UTF8String);
    MADOperationConditionResult *result;
    result = [self evaluateForOperation:operation];
    completion(result);
}

- (MADOperationConditionResult *)evaluateForOperation:(MADOperation *)operation {
    os_log_info(OS_LOG_DEFAULT, "%s\t%s", __PRETTY_FUNCTION__, operation.description.UTF8String);

    MADOperationConditionResult *result = nil;
    NSArray<__kindof NSOperation *> *dependencies = operation.dependencies;
    if (dependencies.count == 0) {
        MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:@"Not Satisified"
                                                                       andMessage:@"Not satisified."];
        NSError *error = [errorUserInfo errorWithDomain:self.name code:MADConditionFailed];
        result = [MADOperationConditionResult newOperationConditionResultFailed:error];
        return result;
    }
    
    for (MADOperation *dependency in dependencies) {
        if ([dependency conformsToProtocol:@protocol(MADOperationConditionPolarQuestionResultProtocol)] &&
            dependency.identifier == self.tag) {
            
            if (((NSObject <MADOperationConditionPolarQuestionResultProtocol> *)dependency).result) {

                result = [MADOperationConditionResult newOperationConditionResultSatisfied];
                
            } else {

                MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:@"Not Satisified"
                                                                               andMessage:@"Not satisified."];
                NSError *error = [errorUserInfo errorWithDomain:self.name code:MADConditionFailed];
                result = [MADOperationConditionResult newOperationConditionResultFailed:error];
                
            }
            break;
        }
    }

    if (result != nil) {
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
