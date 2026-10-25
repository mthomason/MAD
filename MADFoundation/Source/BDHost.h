//
//  BDHost.h
//  CocoaExtensions
//
//  Created by Michael Thomason on 4/13/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  From http://www.bdunagan.com/2009/11/28/iphone-tip-no-nshost/
//  MIT license
//

#ifndef MADFoundation_MADExtensions_BDHost_h
#define MADFoundation_MADExtensions_BDHost_h

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

@interface BDHost : NSObject

	+ (NSString *)addressForHostname:(NSString *)hostname;
	+ (NSArray *)addressesForHostname:(NSString *)hostname;

@end

#endif
