//
//  MADMetaDataCloud.h
//  MADFileManager
//
//  Created by Michael Thomason on 6/22/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADMetaDataCloud_h
#define MAD_MADMetaDataCloud_h

#import <MADFileManager/MADMetaData.h>

@class NSMetadataItem;

@interface MADMetaDataCloud : MADMetaData

- (instancetype)initWithMetadataItem:(NSMetadataItem *)item;

@end

#endif
