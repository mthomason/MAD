//
//  NSData+Comparison.h
//  MAD
//
//  Created by Michael Thomason on 6/12/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_NSData_Comparison_h
#define Reports_NSData_Comparison_h

#import <Foundation/NSData.h>

@interface NSData (Comparison)

- (NSComparisonResult)compareData:(NSData *)data;

@end

#endif
