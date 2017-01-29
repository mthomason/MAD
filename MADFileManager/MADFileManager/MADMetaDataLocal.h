//
//  MADMetaDataLocal.h
//  MADFileManager
//
//  Created by Michael Thomason on 6/22/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADMetaDataLocal_h
#define MAD_MADMetaDataLocal_h

#import <MADFileManager/MADMetaData.h>

@interface MADMetaDataLocal : MADMetaData

- (instancetype)initWithURL:(NSURL *)url;

@end

#endif
