//
//  RptqRect+Extras.h
//  MAD
//
//  Created by Michael on 5/15/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_RptqRect_Extras_h
#define Reports_RptqRect_Extras_h

#import <MAD/RptqRect.h>

@interface RptqRect (Extras)

+ (NSString *)keyOrigin;
+ (NSString *)keySize;
- (struct CGRect)frame;

@end

#endif
