//
//  MADOperationConditionDisplayedAlert.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/20/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADOperationConditionDisplayedAlert_h
#define MAD_Designer_MADOperationConditionDisplayedAlert_h

#import <Foundation/NSObject.h>
#import <MADFoundation/MADOperationCondition.h>

@protocol MADOperationConditionDisplayedAlertProtocol <NSObject>
    - (BOOL)alertDisplayed;
    - (BOOL)alertDisplayedAffirmed;
@end

@interface MADOperationConditionDisplayedAlert : NSObject
    <MADOperationCondition>

    - (instancetype)initWithOperationIdentifier:(NSUInteger)tag;

@end

#endif
