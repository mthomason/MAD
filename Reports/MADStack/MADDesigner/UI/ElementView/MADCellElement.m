//
//  MTCollectionViewCell.m
//  Reports
//
//  Created by Michael Thomason on 12/21/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADCellElement.h"
#import <UIKit/UIMenuController.h>
#import "MADDesignerElementView.h"
#import "MADCellElementDelegate.h"

@interface MADCellElement ()

    @property (nonatomic, weak) MADDesignerElementView *elementView;

@end

@implementation MADCellElement

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    UIMenuController *menu = [UIMenuController sharedMenuController];
    NSMutableArray <UIMenuItem *> *menuItems = menu.menuItems.mutableCopy;
    if (menuItems == nil) {
        menuItems = [NSMutableArray new];
    }
    UIMenuItem *menuItemEdit;
    UIMenuItem *menuItemFormat;
    NSString *edit = NSLocalizedString(@"Edit", @"Edit");
    NSString *format = NSLocalizedString(@"Format", @"Format");
    menuItemEdit = [[UIMenuItem alloc] initWithTitle: edit action: @selector(edit:)];
    menuItemFormat = [[UIMenuItem alloc] initWithTitle: format action: @selector(format:)];
    [menuItems addObject:menuItemEdit];
    [menuItems addObject:menuItemFormat];
    menu.menuItems = menuItems;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    BOOL result = NO;
    
    MTDocumentObjectType objectType = [self.delegate objectTypeRepresentedByCell:self];

    BOOL deleteAction = action == @selector(delete:);
    BOOL editAction = action == @selector(edit:);
    BOOL formatAction = action == @selector(format:);
    
    switch (objectType) {

        case MTDocumentObjectTypeLabelDynamic: {
            result = deleteAction || editAction || formatAction;
            break;
        }
        
        case MTDocumentObjectTypeLabelStatic: {
            result = deleteAction || editAction || formatAction;
            break;
        }
        case MTDocumentObjectTypeAggregate: {
            result = deleteAction || editAction || formatAction;
            break;
        }
            
        // FIXME: Add ability to edit image fields.  84848422

        case MTDocumentObjectTypeImage: {
            result = deleteAction || /*editAction ||*/ formatAction;
            break;
        }
        case MTDocumentObjectTypeWhtiespace: {
            result = deleteAction || formatAction;
            break;
        }
        case MTDocumentObjectTypeBarcode: {
            result = deleteAction || formatAction; // FIXME: Edit action broke on barcodes...
                                                   //   datasource is lost... || editAction;
            break;
        }
        default:
            break;
    }

    return result;
}

- (void)format:(id)sender {
    [self.delegate formatDocumentObjectRepresentedByCell:self];
}

- (void)edit:(id)sender {
    [self.delegate editDocumentObjectRepresentedByCell:self];
}

- (void)delete:(id)sender {
    [self.delegate deleteDocumentObjectRepresentedByCell:self];
}

- (void)addElementView:(MADDesignerElementView *)elementView {
    [self.contentView addSubview:elementView];
    self.elementView = elementView;
}

#pragma mark - Accessibility

- (BOOL)isAccessibilityElement {
    return YES;
}

- (NSString *)accessibilityHint {
    return NSLocalizedString(@"Shows toolbox.", @"Shows toolbox.");
}

- (NSString *)accessibilityLabel {
    return self.elementView.displayStringAttributed.string;
}

@end
