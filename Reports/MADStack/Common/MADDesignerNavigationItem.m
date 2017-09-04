//
//  MADDesignerNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 2/18/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDesignerNavigationItem.h"
#import <UIKit/UIAccessibility.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

@implementation MADDesignerNavigationItem

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        NSString *hint = NSLocalizedString(@"Design the layout for your report.", @"Hint");
        NSString *title;
        title = NSLocalizedString(@"MAD Designer",
                                  @"Title for the store... list program features. ");
        MADLabelTitle *titleView;
        titleView = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
        titleView.text = title;
        titleView.accessibilityHint = hint;
        titleView.accessibilityTraits = UIAccessibilityTraitHeader;
        
        self.titleView = titleView;
        self.title = title;
        self.leftItemsSupplementBackButton = YES;
        
        UIBarButtonItem *doneButton;
        doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                   target: nil
                                                                   action: @selector(done:)];
        self.leftBarButtonItem = doneButton;
    }
    return self;
}

- (void)done:(nullable id)sender {
    @throw NSInternalInconsistencyException;
}

@end
