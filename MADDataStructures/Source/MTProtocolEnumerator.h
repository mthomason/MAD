//
//  MTProtocolEnumerator.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 2/3/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_DataStructures_MTProtocolEnumerator_h
#define MAD_DataStructures_MTProtocolEnumerator_h

#import <Foundation/NSObject.h>

@protocol MTProtocolEnumerator <NSObject>

	- (id)next;
	- (id)previous;

@optional

	- (id)first;
	- (id)last;

@end

#endif
