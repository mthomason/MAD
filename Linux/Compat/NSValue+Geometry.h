//
//  NSValue+Geometry.h
//  Linux/Compat
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Apple's NSValue boxes CoreGraphics values under the CG*Value spellings;
//  GNUstep carries the same accessors under Foundation's NSPoint/NSSize/NSRect
//  names, which are the same structs.  Non-Apple only.
//

#ifndef MADCompat_NSValue_Geometry_h
#define MADCompat_NSValue_Geometry_h

#if !__APPLE__
#import <Foundation/NSValue.h>
#import <Foundation/NSGeometry.h>

@interface NSValue (MADCompatGeometry)

- (CGPoint)CGPointValue;
- (CGSize)CGSizeValue;
- (CGRect)CGRectValue;

@end

#endif /* !__APPLE__ */

#endif /* MADCompat_NSValue_Geometry_h */
