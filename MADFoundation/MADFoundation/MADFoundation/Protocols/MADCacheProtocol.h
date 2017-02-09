//
//  MADCacheProtocol.h
//  MAD
//
//  Created by Michael Thomason on 7/17/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADCacheProtocol_h
#define MAD_MADCacheProtocol_h

@protocol MADCacheProtocol <NSObject>
  @required
    - (NSURL *)cachedFilesDirectory;
  @optional
@end

#endif
