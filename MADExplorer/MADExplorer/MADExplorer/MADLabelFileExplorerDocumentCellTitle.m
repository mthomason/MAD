//
//  MADLabelFileExplorerDocumentCellTitle.m
//  MADExplorer
//
//  Created by Michael Thomason on 6/21/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADLabelFileExplorerDocumentCellTitle.h"
#import <UIKit/UITapGestureRecognizer.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

@implementation MADLabelFileExplorerDocumentCellTitle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [MADLabelFileExplorerDocumentCellTitle commonInitalization:self];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [MADLabelFileExplorerDocumentCellTitle commonInitalization:self];
    }
    return self;
}

+ (void)commonInitalization:(MADLabelFileExplorerDocumentCellTitle *)this {
    this.userInteractionEnabled = YES;
    this.textColor = [MADColorEverydayApps newColorBlue];
    this.clipsToBounds = NO;
    this.numberOfLines = 0;
    this.backgroundColor = [UIColor clearColor];
    this.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    
    SEL handleTap = @selector(handleTapGestureRecognizer:);
    UITapGestureRecognizer *tapGesture;
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget: this
                                                         action: handleTap];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    [this addGestureRecognizer:tapGesture];
}

- (UIColor *)highlightedTextColor {
    return _selected ? [UIColor whiteColor] : [MADColorEverydayApps newColorRed];
}

- (void)setSelected:(BOOL)selected {
    if (_selected != selected) {
        _selected = selected;
        [self setNeedsDisplay];
    }
}

- (void)handleTapGestureRecognizer:(UITapGestureRecognizer *)sender {
    if (_handleTap) _handleTap(sender);
}

@end
