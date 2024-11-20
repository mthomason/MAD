//
//  MADToolboxDisplayProtocol.h
//  MAD
//
//  Created by Michael Thomason on 10/30/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADToolboxDisplayProtocol_h
#define MAD_MADToolboxDisplayProtocol_h

@protocol MADToolboxDisplayProtocol <NSObject>
  @required
    - (void)setClearsBackground:(BOOL)clearsBackground;
@end

#endif
