//
//  UIView+ObjectTag.h
//  Reports
//
//  Created by Michael Thomason on 12/24/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (StringTag)

@property (nonatomic, copy) NSString *stringTag;

- (UIView *)viewWithTagString:(NSString *)object;

@end