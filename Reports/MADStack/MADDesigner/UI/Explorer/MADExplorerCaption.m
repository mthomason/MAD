//
//  NSAttributedString+FileExplorer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/20/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADExplorerCaption.h"
#import <UIKit/NSParagraphStyle.h>
#import <UIKit/UIFont.h>
#import <UIKit/NSAttributedString.h>

@implementation MADExplorerCaption

+ (instancetype)newExplorerCaption:(NSString *)text {
    
    id attributes;
    NSString *caption = text.copy;
    UIFont *font;
    NSMutableParagraphStyle *paragraphStyle;
    id kern = [NSNull null];
    
    paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    
    attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                    kern, NSKernAttributeName,
                    font, NSFontAttributeName,
                    paragraphStyle, NSParagraphStyleAttributeName, nil];
    id attributedString = [[NSMutableAttributedString alloc] initWithString: caption
                                                                 attributes: attributes];
    return attributedString;
}

@end
