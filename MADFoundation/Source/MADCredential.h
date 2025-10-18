//
//  MADCredential.h
//  MAD
//
//  Created by Michael Thomason on 3/10/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADFoundation_MADCredential_h
#define MADFoundation_MADCredential_h

#import <Foundation/NSObject.h>

@interface MADCredential : NSObject <NSCopying, NSSecureCoding>

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;

- (instancetype)initWithUsername:(NSString *)username andPassword:(NSString *)password NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

@end

#endif
