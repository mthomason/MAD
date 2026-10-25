//
//  MADCacheProtocol.h
//  MAD
//
//  Created by Michael Thomason on 7/17/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADCacheProtocol_h
#define MAD_MADCacheProtocol_h

#import <Foundation/NSObject.h>
#import <Foundation/NSURL.h>

@protocol MADCacheProtocol <NSObject>
@required
- (NSURL *)cachedFilesDirectory;
@optional
@end

#endif
