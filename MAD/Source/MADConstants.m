//
//  MADConstants.m
//  MAD
//
//  Created by Michael Thomason on 4/2/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADConstants.h"

NSString * const MADFileExtentionMobleApplicationDocument           = @"mad";
NSString * const MADFileExtentionMobleApplicationDocumentArchive    = @"mada";
NSString * const MADTrademark                                       = @"MAD";

const uint8_t MADFileFormatMagic[8] = { 'M', 'A', 'D', 'F', 'I', 'L', 'E', '\0' };
const uint16_t MADFileFormatMajorVersion = 1;
const uint16_t MADFileFormatMinorVersion = 0;
