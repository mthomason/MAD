//
//  NSError+Constructors.h
//  MAD
//
//  Created by Michael Thomason on 4/1/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (Constructors)

+ (instancetype)errorWithDomain:(NSString *)domain code:(NSInteger)code title:(NSString *)title andMessage:(NSString *)message;

@end
