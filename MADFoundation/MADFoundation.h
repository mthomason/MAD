//
//  MADFoundation.h
//  MADFoundation
//
//  Created by Michael Thomason on 9/18/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import <Foundation/NSObjCRuntime.h>

//! Project version number for MADFoundation.
FOUNDATION_EXPORT double MADFoundationVersionNumber;

//! Project version string for MADFoundation.
FOUNDATION_EXPORT const unsigned char MADFoundationVersionString[];

#import <MADFoundation/madlib.h>
#import <MADFoundation/madmacros.h>
#import <MADFoundation/madlog.h>
#import <MADFoundation/BDHost.h>
#import <MADFoundation/MADOperationPromptErrorProtocol.h>
#import <MADFoundation/MADOperationResultStringProtocol.h>
#import <MADFoundation/MADApplicationProtocol.h>
#import <MADFoundation/MADDataProtocol.h>
#import <MADFoundation/MADCacheProtocol.h>
#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADDataColumn.h>
#import <MADFoundation/MADNotificationProgress.h>
#import <MADFoundation/MADDataType.h>
#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/MADDataTableVirtual.h>
#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADURLFactory.h>
#import <MADFoundation/MADProgress.h>
#import <MADFoundation/MADDataTableType.h>
#import <MADFoundation/MADOperationCondition.h>
#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationConditionResult.h>
#import <MADFoundation/MADBlockObserver.h>
#import <MADFoundation/MADBlockOperation.h>
#import <MADFoundation/MADGroupOperation.h>
#import <MADFoundation/MADOperationObserver.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MADFoundation/MADOperationTestResults.h>
#import <MADFoundation/MADOperationBooleanAnd.h>
#import <MADFoundation/MADOperationConditionHasResultString.h>
#import <MADFoundation/MADOperationConditionMissingResultString.h>
#import <MADFoundation/MADOperationConditionTestConnectionSuccess.h>
#import <MADFoundation/MADOperationConditionHasResultStringResult.h>
#import <MADFoundation/NSOperation+CompletionBlock.h>
#import <MADFoundation/MADKeyChain.h>
#import <MADFoundation/MADStringUtilities.h>
#import <MADFoundation/NSData+Comparison.h>
#import <MADFoundation/NSString+Comparison.h>
