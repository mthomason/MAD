//
//  NSPropertyListSerialization+Stream.h
//  Linux/Compat
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  GNUstep declares +propertyListWithStream:options:format:error: but its
//  implementation is a stub: it returns nil, sets no error and never reads
//  the stream (measured 2026-10-06; the same bytes parse through
//  +propertyListWithData:).  MADDataTable's -loadFromCacheWithUrl: is built
//  on it, so the shim reads the stream out and defers to the data variant --
//  the same answer, through the call that works.  Non-Apple only.
//

#ifndef MADCompat_NSPropertyListSerialization_Stream_h
#define MADCompat_NSPropertyListSerialization_Stream_h

#if !__APPLE__
#import <Foundation/NSPropertyList.h>

@interface NSPropertyListSerialization (MADCompatStream)

+ (id)propertyListWithStream:(NSInputStream *)stream
					 options:(NSUInteger)opt
					  format:(NSPropertyListFormat *)format
					   error:(NSError **)error;

@end

#endif /* !__APPLE__ */

#endif /* MADCompat_NSPropertyListSerialization_Stream_h */
