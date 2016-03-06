//
//  MTCollectionViewCell.m
//  Reports
//
//  Created by Michael Thomason on 12/21/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTCollectionViewCellElement.h"
#import "MADDesignerElementView.h"
#import "MADDesignerElementView.h"

@interface MTCollectionViewCellElement ()

@property (nonatomic, weak) MADDesignerElementView *elementView;

@end

@implementation MTCollectionViewCellElement

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
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
    });
    

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
            result = deleteAction || formatAction; // FIXME: Edit action broke on barcodes... datasource is lost... || editAction;
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
