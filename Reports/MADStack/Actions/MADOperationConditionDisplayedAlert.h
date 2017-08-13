//
//  MADOperationConditionDisplayedAlert.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/20/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADOperationConditionDisplayedAlert_h
#define MAD_Designer_MADOperationConditionDisplayedAlert_h

#import <Foundation/NSObject.h>
#import "MADOperationCondition.h"

@protocol MADOperationConditionDisplayedAlertProtocol <NSObject>
    - (BOOL)alertDisplayed;
@end

@interface MADOperationConditionDisplayedAlert : NSObject
    <MADOperationCondition>

    - (instancetype)initWithOperationIdentifier:(NSUInteger)tag;
    @property (nonatomic, assign) BOOL reverseCondition;

@end

#endif
