//
//  NSData+ReadingOptions.h
//  Linux/Compat
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  GNUstep's NSData reads a URL but has neither the options/error variant nor
//  the NSDataReadingOptions type.  The shim takes the options as the
//  underlying integer and ignores them -- GNUstep has no mapping behaviour to
//  offer -- and reports failure through the classic reader.  Non-Apple only.
//

#ifndef MADCompat_NSData_ReadingOptions_h
#define MADCompat_NSData_ReadingOptions_h

#if !__APPLE__
#import <Foundation/NSData.h>

@interface NSData (MADCompatReadingOptions)

+ (instancetype)dataWithContentsOfURL:(NSURL *)url
							  options:(NSUInteger)readOptionsMask
								error:(NSError **)errorPtr;

@end

#endif /* !__APPLE__ */

#endif /* MADCompat_NSData_ReadingOptions_h */
