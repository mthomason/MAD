//
//  MTProtocolLog.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/13/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_DataStructures_MTProtocolLog_h
#define MAD_DataStructures_MTProtocolLog_h

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>
#import <Foundation/NSAttributedString.h>

@protocol MTProtocolLog <NSObject>
@required

	- (NSString *)toString;
	- (NSString *)toStringDebug;
	- (NSString *)toStringHumanReadable;

@optional

	- (NSString *)toStringExpressive;
	- (NSString *)toStringSymbolic;
	- (NSString *)toStringName;
	- (NSAttributedString *)toAttributedString;

@end

#endif
