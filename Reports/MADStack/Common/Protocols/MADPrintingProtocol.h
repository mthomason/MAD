//
//  MADPrintingProtocol.h
//  Reports
//
//  Created by Michael Thomason on 2/12/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
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
