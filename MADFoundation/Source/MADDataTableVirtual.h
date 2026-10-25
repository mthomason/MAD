//
//  MADDataTableVirtual.h
//  MAD
//
//  Created by Michael Thomason on 4/25/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADDataTableVirtual_h
#define Reports_MADDataTableVirtual_h

#import <MADFoundation/MADDataTable.h>

@interface MADDataTableVirtual : MADDataTable

/// Indexed access to the rows, equivalent to -objectAtRow:.
- (id)objectAtIndexedSubscript:(NSUInteger)index;

@end

#endif
