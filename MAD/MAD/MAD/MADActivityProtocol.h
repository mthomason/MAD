//
//  MADActivityProtocol.h
//  MAD
//
//  Created by Michael Thomason on 7/21/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADActivityProtocol_h
#define MAD_MADActivityProtocol_h

@class UIViewController;

@protocol MADActivityProtocol <NSObject>
	- (UIViewController *)activeViewController;
@end

#endif
