//
//  MADConstants.m
//  MAD
//
//  Created by Michael Thomason on 4/2/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import <Foundation/Foundation.h>
#import <string.h>

#import "MADConstants.h"

NSString * const MADFileExtentionMobleApplicationDocument           = @"mad";
NSString * const MADFileExtentionMobleApplicationDocumentArchive    = @"mada";
NSString * const MADTrademark                                       = @"MAD";

const uint8_t MADFileFormatMagic[8] = { 'M', 'A', 'D', 'F', 'I', 'L', 'E', '\0' };
const uint16_t MADFileFormatMajorVersion = 1;
const uint16_t MADFileFormatMinorVersion = 0;

NSString * const MADFileFormatErrorDomain = @"MADFileFormatErrorDomain";

BOOL MADFileFormatHeaderIsSupported(const uint8_t *bytes, NSUInteger length,
									NSError * __autoreleasing *error) {
	// A short file or one without the magic is a v0 body: the pre-header format,
	// still supported, and there is no version word to read.
	if (length < MADFileFormatHeaderLength) return YES;
	if (memcmp(bytes, MADFileFormatMagic, 8) != 0) return YES;

	uint16_t major = (uint16_t)(bytes[8] | (bytes[9] << 8));
	uint16_t minor = (uint16_t)(bytes[10] | (bytes[11] << 8));
	if (major < MADFileFormatMajorVersion ||
		(major == MADFileFormatMajorVersion && minor <= MADFileFormatMinorVersion)) {
		return YES;
	}
	if (error) {
		*error = [NSError errorWithDomain: MADFileFormatErrorDomain code: 1
								 userInfo: @{ NSLocalizedDescriptionKey:
			[[NSString alloc] initWithFormat:
				@"This document was written by a newer version of MAD Designer "
				@"(format %u.%u). Upgrade MAD Designer to open it.", major, minor] }];
	}
	return NO;
}
