//
//  MADMetaDataLocal.h
//  MADFileManager
//
//  Created by Michael Thomason on 6/22/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADMetaDataLocal_h
#define MAD_MADMetaDataLocal_h

#import <MADFileManager/MADMetaData.h>
#import <Foundation/NSURL.h>

@interface MADMetaDataLocal : MADMetaData

- (instancetype)initWithURL:(NSURL *)url;

@end

#endif
