//
//  MADPreference.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/17/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

//#import <Foundation/Foundation.h>

@interface MADPreference : NSObject

- (instancetype)initWithKey:(NSString *)key;
- (instancetype)initWithKey:(NSString *)key allowCloud:(BOOL)allowCloud encrypt:(BOOL)encrypt;

@end
