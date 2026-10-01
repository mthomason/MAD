//
//  MADConstants.h
//  MAD
//
//  Created by Michael Thomason on 4/2/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADDesigner_Constants_h
#define MADDesigner_Constants_h

#import <stdint.h>

@class NSString;

extern NSString * const MADFileExtentionMobleApplicationDocumentArchive;
extern NSString * const MADFileExtentionMobleApplicationDocument;
extern NSString * const MADTrademark;

// The `.mad` v1 header, per MAD_FORMAT.md section 7.1: a fixed 16 bytes ahead of the
// bzip2 stream, so a document is identified by content rather than by its extension.
extern const uint8_t MADFileFormatMagic[8];		// "MADFILE\0"
extern const uint16_t MADFileFormatMajorVersion;	// 1
extern const uint16_t MADFileFormatMinorVersion;	// 0
#define MADFileFormatHeaderLength 16u

#endif
