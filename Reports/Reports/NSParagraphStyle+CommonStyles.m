//
//  NSParagraphStyle+CommonStyles.m
//  MAD
//
//  Created by Michael Thomason on 5/31/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "NSParagraphStyle+CommonStyles.h"

@implementation NSParagraphStyle (CommonStyles)

+ (NSParagraphStyle *)titleBarStyle {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    [paragraphStyle setBaseWritingDirection:NSWritingDirectionLeftToRight];
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    return paragraphStyle;
}

@end
