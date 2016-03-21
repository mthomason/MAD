//
//  MADOperationConditionDisplayedAlert.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/20/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADOperationConditionDisplayedAlert_h
#define MAD_Designer_MADOperationConditionDisplayedAlert_h

#import <Foundation/NSObject.h>
#import "MADOperationCondition.h"

@protocol MADOperationConditionDisplayedAlertProtocol <NSObject>

    - (bool)alertDisplayed;

@end

@interface MADOperationConditionDisplayedAlert : NSObject
    <MADOperationCondition>

    - (instancetype)initWithTag:(NSUInteger)tag;
    @property (nonatomic, assign) bool reverseCondition;

@end

#endif
