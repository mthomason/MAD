//
//  MADOperationConditionDisplayedAlert.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/20/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADOperationConditionDisplayedAlert_h
#define MAD_Designer_MADOperationConditionDisplayedAlert_h

#import <Foundation/NSObject.h>
#import <MADFoundation/MADOperationCondition.h>

@protocol MADOperationConditionDisplayedAlertProtocol <NSObject>
	- (BOOL)alertDisplayed;
	- (BOOL)alertDisplayedAffirmed;
@end

@interface MADOperationConditionDisplayedAlert : NSObject <MADOperationCondition>
	- (instancetype)initWithOperationIdentifier:(NSUInteger)tag;

@end

#endif
