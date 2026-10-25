//
//  MADPrintingProtocol.h
//  Reports
//
//  Created by Michael Thomason on 2/12/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADPrintingProtocol_h
#define Reports_MADPrintingProtocol_h

#import <Foundation/NSObject.h>

@class MADPrintPageRenderer;

@protocol MADPrintingProtocol <NSObject>
@required
	- (MADPrintPageRenderer *)printPageRenderer;
@end

#endif
