//
//  MADCredential.h
//  MAD
//
//  Created by Michael Thomason on 3/10/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MADCredential : NSObject <NSCopying>

    - (instancetype)initWithUsername:(NSString *)username andPassword:(NSString *)password;

    @property (nonatomic, copy) NSString *username;
    @property (nonatomic, copy) NSString *password;

@end

