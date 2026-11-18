//
//  NSPropertyListSerialization+Stream.m
//  Windows/Engine/Compat (copied from Linux/Compat)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "NSPropertyListSerialization+Stream.h"

#if !__APPLE__
#import <Foundation/NSStream.h>
#import <Foundation/NSError.h>
// The Windows GNUstep headers do not pull NSData in before this translation
// unit uses NSMutableData (the Linux header order happens to).  Import it
// explicitly; it is a no-op on Linux, whose headers already reach it.
#import <Foundation/NSData.h>

@implementation NSPropertyListSerialization (MADCompatStream)

// The warning that this shadows the primary class's implementation is the
// point: GNUstep's is the stub described in the header.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

+ (id)propertyListWithStream:(NSInputStream *)stream
					 options:(NSUInteger)opt
					  format:(NSPropertyListFormat *)format
					   error:(NSError **)error {
	[stream open];
	NSMutableData *data = [NSMutableData data];
	uint8_t buffer[4096];
	NSInteger read = 0;
	while ((read = [stream read:buffer maxLength:sizeof(buffer)]) > 0) {
		[data appendBytes:buffer length:(NSUInteger)read];
	}
	[stream close];
	if (read < 0) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:@"MADCompatPropertyList"
										 code:1
									 userInfo:nil];
		}
		return nil;
	}
	return [self propertyListWithData:data options:opt format:format error:error];
}

#pragma clang diagnostic pop

@end

#endif /* !__APPLE__ */
