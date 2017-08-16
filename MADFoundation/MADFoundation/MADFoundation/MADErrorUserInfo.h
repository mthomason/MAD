//
//  MADErrorUserInfo.h
//  MAD
//
//  Created by Michael Thomason on 3/5/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADErrorUserInfo_h
#define MAD_MADErrorUserInfo_h

#import <Foundation/NSObject.h>

@interface MADErrorUserInfo : NSObject

    - (instancetype)initWithTitle: (NSString *)title andMessage: (NSString *)message;
    - (NSError *)errorWithDomain: (NSString *)domain code: (NSInteger)code;

@end

#endif
