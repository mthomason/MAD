//
//  MADViewControllerProtocol.h
//  MAD
//
//  Created by Michael Thomason on 11/11/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADViewControllerProtocol_h
#define MAD_MADViewControllerProtocol_h

@protocol MADViewControllerProtocol <NSObject>

    - (BOOL)hidesStatusBar;
    - (void)setHidesStatusBar:(BOOL)hidesStatusBar;

@end

#endif
