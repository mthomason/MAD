//
//  NSError+MADOperationErrors.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_NSError_MADOperationErrors_h
#define MAD_Designer_NSError_MADOperationErrors_h

#import <Foundation/NSError.h>

typedef NS_ENUM(NSUInteger, MADOperationErrorCode) {
    MADConditionFailed = 1,
    MADExecutionFailed = 2
};

@interface NSError (MADOperationErrors)

    + (instancetype)errorWithCode:(NSInteger)code;
    + (instancetype)errorWithCode:(NSInteger)code userInfo:(NSDictionary *)info;

@end

#endif
