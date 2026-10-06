//
//  MADCacheProtocol.h
//  MAD
//
//  Created by Michael Thomason on 7/17/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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
