//
//  MADMetaDataLocal.h
//  MADFileManager
//
//  Created by Michael Thomason on 6/22/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADMetaDataLocal_h
#define MAD_MADMetaDataLocal_h

#import <MADFileManager/MADFileManager.h>

@interface MADMetaDataLocal : MADMetaData

- (instancetype)initWithURL:(NSURL *)url;

@end

#endif
