//
//  MADOperationConditionSupport.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/16/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADOperationErrorCode_h
#define MAD_Designer_MADOperationErrorCode_h

#import <Foundation/NSObject.h>

@class MADOperation;

extern NSString * MADOperationConditionKey;

@interface MADOperationConditionResult : NSObject

    @property (nonatomic, readonly) BOOL isSucceed;
    @property (nonatomic, readonly) NSError * error;

    + (MADOperationConditionResult *)satisfied;
    + (MADOperationConditionResult *)failed:(NSError *)error;
    + (void)evaluateConditions:(NSArray *)conditions operation:(MADOperation *)operation completion:(void(^)(NSArray * errors))completion;

@end

#endif
