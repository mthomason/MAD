//
//  NSAttributedString+FileExplorer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/20/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "NSAttributedString+FileExplorer.h"
#import <UIKit/NSParagraphStyle.h>
#import <UIKit/UIFont.h>
#import <UIKit/NSAttributedString.h>

@implementation NSAttributedString (FileExplorer)

+ (instancetype)newAttributedStringCaptionWithText:(NSString *)text {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    
    id attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                     [NSNull null], NSKernAttributeName,
                     font, NSFontAttributeName,
                     paragraphStyle, NSParagraphStyleAttributeName, nil];
    NSString *string = text.copy;
    id attributedString = [[NSMutableAttributedString alloc] initWithString: string
                                                                 attributes: attributes];
    return attributedString;
}

@end
