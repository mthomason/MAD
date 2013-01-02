//
//  MTFont.h
//  Reports
//
//  Created by Michael Thomason on 1/1/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTFont : NSObject

- (id)initWithFamilyName:(NSString *)familyName;
- (id)initWithFamilyName:(NSString *)familyName andPointSize:(CGFloat)pointSize;

+ (NSArray *)familyNames;

@end