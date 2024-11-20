//
//  MADFoundation.h
//  MADFoundation
//
//  Created by Michael Thomason on 9/18/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import <Foundation/NSObjCRuntime.h>

//! Project version number for MADFoundation.
FOUNDATION_EXPORT double MADFoundationVersionNumber;

//! Project version string for MADFoundation.
FOUNDATION_EXPORT const unsigned char MADFoundationVersionString[];


#import <MADFoundation/madlib.h>

#import <MADFoundation/BDHost.h>

#import <MADFoundation/MADOperationPromptErrorProtocol.h>
#import <MADFoundation/MADOperationResultStringProtocol.h>
#import <MADFoundation/MADApplicationProtocol.h>
#import <MADFoundation/MADAppDelegate.h>
#import <MADFoundation/MADDataProtocol.h>
#import <MADFoundation/MADCacheProtocol.h>

#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADDataColumn.h>
#import <MADFoundation/MADNotificationProgress.h>

#import <MADFoundation/MADDataType.h>
#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/MADDataTablePlist.h>
#import <MADFoundation/MADDataTableVirtual.h>

#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADURL.h>
#import <MADFoundation/MADProgress.h>

#import <MADFoundation/MADAssert.h>
#import <MADFoundation/MADThread.h>
#import <MADFoundation/MADFilename.h>
#import <MADFoundation/MADDataTableType.h>
#import <MADFoundation/MADErrorUserInfo.h>
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

#import <MADFoundation/NSOperation+Advanced.h>
#import <MADFoundation/MADKeyChain.h>

#import <MADFoundation/NSData+Comparson.h>
#import <MADFoundation/UIScreen+Properties.h>
#import <MADFoundation/NSError+MADOperationErrors.h>
#import <MADFoundation/NSString+Common.h>
