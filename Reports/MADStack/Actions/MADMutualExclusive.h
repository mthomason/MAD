//
//  MADMutualExclusive.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/23/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADMutualExclusiveCondition_h
#define MAD_Designer_MADMutualExclusiveCondition_h

#import <Foundation/NSObject.h>
#import <MADFoundation/MADOperationCondition.h>

@interface MADMutualExclusiveCondition : NSObject
    <MADOperationCondition>

    + (instancetype)newMutualExclusiveConditionForClass:(Class)class;
    + (instancetype)newMutualExclusiveConditionAlertMutex;
    + (instancetype)newMutualExclusiveConditionViewControllerMutex;

@end

#endif
