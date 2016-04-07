//
//  MADViewControllerProtocol.h
//  MAD
//
//  Created by Michael Thomason on 11/11/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADViewControllerProtocol_h
#define MAD_MADViewControllerProtocol_h

@protocol MADViewControllerProtocol <NSObject>

    - (bool)hidesStatusBar;
    - (void)setHidesStatusBar:(bool)hidesStatusBar;

@end

#endif
