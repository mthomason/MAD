//
//  MADConstants.h
//  MAD
//
//  Created by Michael Thomason on 4/2/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADDesigner_Constants_h
#define MADDesigner_Constants_h

#import <stdint.h>
#import <Foundation/NSObjCRuntime.h>

@class NSString;
@class NSError;

extern NSString * const MADFileExtentionMobleApplicationDocumentArchive;
extern NSString * const MADFileExtentionMobleApplicationDocument;
extern NSString * const MADTrademark;

// The `.mad` v1 header, per docs/project/MAD_FORMAT.md section 7.1: a fixed 16 bytes ahead of the
// bzip2 stream, so a document is identified by content rather than by its extension.
extern const uint8_t MADFileFormatMagic[8];		// "MADFILE\0"
extern const uint16_t MADFileFormatMajorVersion;	// 1
extern const uint16_t MADFileFormatMinorVersion;	// 0
#define MADFileFormatHeaderLength 16u

extern NSString * const MADFileFormatErrorDomain;

/// YES for a v0 document (no magic header), the current 1.0 header, and any 1.x
/// whose minor is no newer than this build's.  A newer major or minor fills
/// `error` with an upgrade message.  The header is 16 bytes: 8 magic bytes, two
/// little-endian version words, then four flag bytes.
extern BOOL MADFileFormatHeaderIsSupported(const uint8_t *bytes,
										   NSUInteger length,
										   NSError * __autoreleasing *error);

#endif
