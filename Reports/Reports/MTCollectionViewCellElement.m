//
//  MTCollectionViewCell.m
//  Reports
//
//  Created by Michael Thomason on 12/21/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTCollectionViewCellElement.h"

@implementation MTCollectionViewCellElement

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIMenuController *menu = [UIMenuController sharedMenuController];
        NSMutableArray *menuItems = [[menu menuItems] mutableCopy];
        if (menuItems == nil) {
            menuItems = [[NSMutableArray alloc] init];
        }
        UIMenuItem *menuItemEdit = [[UIMenuItem alloc] initWithTitle: NSLocalizedString(@"Edit", @"Edit")
                                                              action: @selector(edit:)];
        UIMenuItem *menuItemFormat = [[UIMenuItem alloc] initWithTitle: NSLocalizedString(@"Format", @"Format")
                                                                action: @selector(format:)];
        [menuItems addObject:menuItemEdit];
        [menuItems addObject:menuItemFormat];
        [menu setMenuItems:menuItems];
        [menuItemEdit release];
        [menuItemFormat release];
        [menuItems release];
    });
    

}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    for (UIView *subview in [[self contentView] subviews]) {
        [subview setNeedsDisplay];
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    BOOL result = NO;
    if (action == @selector(delete:) || action == @selector(edit:) || action == @selector(format:)) {
        result = YES;
    }
    return result;
}

- (void)format:(id)sender {
    [[self delegate] editDocumentObjectRepresentedByCell:self];
}

//- (void)duplicate:(id)sender {
//    [[self delegate] editDocumentObjectRepresentedByCell:self];
//}

//- (void)cut:(id)sender {
//    [[self delegate] editDocumentObjectRepresentedByCell:self];
//}

//- (void)copy:(id)sender {
//    [[self delegate] editDocumentObjectRepresentedByCell:self];
//}

//- (void)paste:(id)sender {
//    [[self delegate] editDocumentObjectRepresentedByCell:self];
//}

- (void)edit:(id)sender {
    [[self delegate] editDocumentObjectRepresentedByCell:self];
}

- (void)delete:(id)sender {
    [[self delegate] deleteDocumentObjectRepresentedByCell:self];
}

@end
