//
//  NSString+Comparison.h
//  MADFoundation
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

//  The defined order every text comparison in the export path routes through
//  (MAD_CLI.md's `mad export` section): case-fold, then code-point order on
//  the UTF-8 bytes.  It is first-party and platform-independent -- the cache's
//  LSASC collation, the in-memory sort descriptors and the report formatter's
//  group-boundary walk all compare through it, so key equality and row order
//  agree everywhere, on Apple and on GNUstep.

#ifndef Reports_NSString_Comparison_h
#define Reports_NSString_Comparison_h

#import <Foundation/NSString.h>
#import <Foundation/NSObjCRuntime.h>

NSComparisonResult MADStringOrderedCompareUTF8(const char *bytes1, NSUInteger length1,
											   const char *bytes2, NSUInteger length2);

@interface NSString (Comparison)

- (NSComparisonResult)mad_orderedCompare:(NSString *)other;

@end

#endif
