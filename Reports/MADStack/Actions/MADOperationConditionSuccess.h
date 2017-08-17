//
//  MADOperationConditionSuccess.h
//  MAD Designer
//
//  Created by Michael on 8/17/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADOperationConditionSuccess_h
#define MAD_Designer_MADOperationConditionSuccess_h

#import <Foundation/NSObject.h>
#import <MADFoundation/MADOperationCondition.h>

@interface MADOperationConditionSuccess : NSObject
    <MADOperationCondition>
    - (instancetype)initWithKey:(NSString *)key;
    @property (nonatomic, assign) BOOL reverseCondition;
@end

#endif
