//
//  MADOperationConditionTestConnectionSuccess.h
//  MAD Designer
//
//  Created by Michael on 8/12/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADOperationConditionTestConnectionSuccess_h
#define MAD_Designer_MADOperationConditionTestConnectionSuccess_h

#import <Foundation/NSObject.h>
#import <MADFoundation/MADOperationCondition.h>

@interface MADOperationConditionTestConnection : NSObject <MADOperationCondition>
@end

@interface MADOperationConditionTestConnectionSuccess : MADOperationConditionTestConnection
@end

@interface MADOperationConditionTestConnectionFailuare : MADOperationConditionTestConnection
@end

#endif
