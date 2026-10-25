//
//  MADActivityProtocol.h
//  MAD
//
//  Created by Michael Thomason on 7/21/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADActivityProtocol_h
#define MAD_MADActivityProtocol_h

@class UIViewController;

@protocol MADActivityProtocol <NSObject>
	- (UIViewController *)activeViewController;
@end

#endif
