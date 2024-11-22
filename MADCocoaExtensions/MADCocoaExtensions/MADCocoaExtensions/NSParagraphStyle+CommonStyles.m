//
//  NSParagraphStyle+CommonStyles.m
//  MAD
//
//  Created by Michael Thomason on 5/31/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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
