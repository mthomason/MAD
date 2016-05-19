//
//  NSParagraphStyle+CommonStyles.m
//  MAD
//
//  Created by Michael Thomason on 5/31/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "NSParagraphStyle+CommonStyles.h"

@implementation NSParagraphStyle (CommonStyles)

+ (NSParagraphStyle *)newParagraphStyleTitleBar {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    return paragraphStyle;
}

@end
