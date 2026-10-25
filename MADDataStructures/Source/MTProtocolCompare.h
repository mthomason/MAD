//
//  MTProtocolCompare.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 12/14/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_DataStructures_MTProtocolCompare_h
#define MAD_DataStructures_MTProtocolCompare_h

@protocol MTProtocolCompare <NSObject>

@required

	- (BOOL)isEqualTo:(id)sender;

@optional

	- (BOOL)isGreaterThan:(id)sender;
	- (BOOL)isLessThan:(id)sender;
	- (BOOL)isGreaterThanOrEqualTo:(id)sender;
	- (BOOL)isLessThanOrEqualToSender:(id)sender;

@end

#endif
