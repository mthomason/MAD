//
//  MADActivityProtocol.h
//  MAD
//
//  Created by Michael Thomason on 7/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADActivityProtocol_h
#define MAD_MADActivityProtocol_h

@class UIViewController;

@protocol MADActivityProtocol <NSObject>

- (UIViewController *)activeViewController;

@end

#endif
