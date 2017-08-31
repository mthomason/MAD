//
//  MADCredential.h
//  MAD
//
//  Created by Michael Thomason on 3/10/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADFoundation_MADCredential_h
#define MADFoundation_MADCredential_h

#import <Foundation/NSObject.h>

@interface MADCredential : NSObject <NSCopying>

    - (instancetype)initWithUsername:(NSString *)username andPassword:(NSString *)password;

    @property (nonatomic, copy) NSString *username;
    @property (nonatomic, copy) NSString *password;

@end

#endif
