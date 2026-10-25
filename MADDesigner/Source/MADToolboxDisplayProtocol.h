//
//  MADToolboxDisplayProtocol.h
//  MAD
//
//  Created by Michael Thomason on 10/30/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADToolboxDisplayProtocol_h
#define MAD_MADToolboxDisplayProtocol_h

#import <Foundation/NSObject.h>

@protocol MADToolboxDisplayProtocol <NSObject>
  @required
    - (void)setClearsBackground:(BOOL)clearsBackground;
@end

#endif
