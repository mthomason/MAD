//
//  MADLabelFileExplorerDocumentCellTitle.m
//  MADExplorer
//
//  Created by Michael Thomason on 6/21/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADLabelFileExplorerDocumentCellTitle.h"
#import <UIKit/UITapGestureRecognizer.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

@implementation MADLabelFileExplorerDocumentCellTitle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInitalization];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInitalization];
    }
    return self;
}

- (void)commonInitalization {
    self.userInteractionEnabled = YES;
    self.textColor = [MADColorEverydayApps newColorBlue];
    self.clipsToBounds = NO;
    self.numberOfLines = 0;
    self.backgroundColor = [UIColor clearColor];
    self.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    
    SEL handleTap = @selector(handleTapGestureRecognizer:);
    UITapGestureRecognizer *tapGesture;
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                         action: handleTap];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:tapGesture];
}

- (UIColor *)highlightedTextColor {
    return _selected ? [UIColor whiteColor] : [MADColorEverydayApps newColorRed];
}

- (UIColor *)disabledTextColor {
    return _selected ? [UIColor whiteColor] : [UIColor lightGrayColor];
}

- (UIColor *)enabledTextColor {
    return _selected ? [UIColor whiteColor] : [MADColorEverydayApps newColorBlue];
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
