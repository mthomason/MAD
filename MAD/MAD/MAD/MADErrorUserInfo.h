//
//  MADErrorUserInfo.h
//  MAD
//
//  Created by Michael Thomason on 3/5/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MADErrorUserInfo : NSObject

    - (instancetype)initWithTitle:(NSString *)title andMessage:(NSString *)message;
    - (NSError *)errorWithDomain: (NSString *)domain code: (NSInteger)code;

    @property (nonatomic, strong, readonly) NSDictionary *userinfo;

@end
