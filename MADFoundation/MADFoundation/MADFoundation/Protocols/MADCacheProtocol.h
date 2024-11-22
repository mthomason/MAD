//
//  MADCacheProtocol.h
//  MAD
//
//  Created by Michael Thomason on 7/17/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADCacheProtocol_h
#define MAD_MADCacheProtocol_h

@protocol MADCacheProtocol <NSObject>
@required
	- (NSURL *)cachedFilesDirectory;
@optional
@end

#endif
