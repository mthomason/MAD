//
//  MADPathUtilities.h
//  MAD
//
//  Created by Michael Thomason on 5/21/16.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#ifndef MAD_Reports_NSString_RelativePath_h
#define MAD_Reports_NSString_RelativePath_h

#import <Foundation/NSString.h>

@interface MADPathUtilities : NSObject

	+ (NSString *)stringWithPath:(NSString *)basePath relativeTo:(NSString *)anchorPath;

@end

#endif
