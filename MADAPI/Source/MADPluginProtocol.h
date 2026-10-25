//
//  MADPluginProtocol.h
//  MADAPI
//
//  Created by Michael on 9/3/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADPluginProtocol_h
#define MADPluginProtocol_h

#import <Foundation/NSObject.h>

@protocol MADPluginProtocol <NSObject>

	+ (NSString *)imageIconName;
	+ (NSString *)driverName;

@end

#endif /* MADPluginProtocol_h */
