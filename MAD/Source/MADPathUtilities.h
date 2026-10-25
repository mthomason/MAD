//
//  MADPathUtilities.h
//  MAD
//
//  Created by Michael Thomason on 5/21/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Reports_NSString_RelativePath_h
#define MAD_Reports_NSString_RelativePath_h

#import <Foundation/NSString.h>

@interface MADPathUtilities : NSObject

	+ (NSString *)stringWithPath:(NSString *)basePath relativeTo:(NSString *)anchorPath;

@end

#endif
