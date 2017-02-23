//
//  MADQueryNavigationItem.m
//  MAD Designer
//
//  Created by Michael on 2/18/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryNavigationItem.h"
#import <UIKit/UIAccessibility.h>
#import <UIKit/UIApplication.h>
#import "MADLabelTitle.h"
#import "MADQueryNavigationProtocol.h"

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
        editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemEdit
                                                                   target: self
                                                                   action: @selector(actionEdit:)];
        self.leftBarButtonItem = doneButton;
        self.rightBarButtonItem = editButton;
    }
    return self;
}

- (void)done:(nullable id)sender {
    @throw NSInternalInconsistencyException;
}

- (void)actionEdit:(nullable id)sender {
    UIBarButtonItem *editButton;
    editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                               target: self
                                                               action: @selector(actionFinishEdit:)];
    [self setLeftBarButtonItem: nil animated: YES];
    [self setRightBarButtonItem: editButton animated: YES];
    [self.delegate edit:self];
}

- (void)actionFinishEdit:(nullable id)sender {
    UIBarButtonItem *editButton, *doneButton;
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                               target: nil
                                                               action: @selector(done:)];
    editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemEdit
                                                               target: self
                                                               action: @selector(actionEdit:)];
    [self setLeftBarButtonItem: doneButton animated: YES];
    [self setRightBarButtonItem: editButton animated: YES];
    [self.delegate edit:self];
}

@end
