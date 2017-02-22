//
//  MADQueryNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 2/18/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryNavigationItem.h"
#import <UIKit/UIAccessibility.h>
#import "MADLabelTitle.h"

@implementation MADQueryNavigationItem

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        NSString *hint = NSLocalizedString(@"Design the query for your report.", @"Hint");
        NSString *title;
        title = NSLocalizedString(@"MAD Query",
                                  @"Title for the store... list program features. ");
        MADLabelTitle *titleView;
        titleView = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
        titleView.text = title;
        titleView.accessibilityHint = hint;
        titleView.accessibilityTraits = UIAccessibilityTraitHeader;
        
        self.titleView = titleView;
        self.title = title;
        self.leftItemsSupplementBackButton = YES;
        
        UIBarButtonItem *doneButton, *editButton;
        doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                   target: nil
                                                                   action: @selector(done:)];
        editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                   target:nil
                                                                   action:@selector(edit:)];
        self.leftBarButtonItem = doneButton;
        self.rightBarButtonItem = editButton;
    }
    return self;
}

- (void)done:(nullable id)sender {
    @throw NSInternalInconsistencyException;
}

- (void)edit:(nullable id)sender {
    @throw NSInternalInconsistencyException;
}

@end
