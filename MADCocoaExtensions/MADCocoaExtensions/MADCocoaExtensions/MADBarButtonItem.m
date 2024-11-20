//
//  UIBarButtonItem+Constructors.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 5/29/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBarButtonItem.h"
#import <UIKit/UIImage.h>
#import <UIKit/UIActivityIndicatorView.h>

@implementation MADBarButtonItem

+ (instancetype)newBarButtonItemEdit:(id)target action:(SEL)action {
    id button = [[self alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemEdit
                                                   target: target
                                                   action: action];
    return button;
}

+ (instancetype)newBarButtonItemDuplicate:(id)target action:(SEL)action {
    id barButtonItemDuplicate = nil;

    UIImage *imageDuplcate = [UIImage imageNamed: @"MADImageToolbarDuplicate"];
    barButtonItemDuplicate = [[self alloc] initWithImage: imageDuplcate
                                                   style: UIBarButtonItemStylePlain
                                                  target: target
                                                  action: action];
    imageDuplcate = nil;
    [barButtonItemDuplicate setEnabled: NO];
    return barButtonItemDuplicate;
}

+ (instancetype)newBarButtonItemEditDone:(id)target action:(SEL)action {
    id button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                              target: target
                                                              action: action];
    return button;
}

+ (instancetype)newBarButtonItemActivityIndicator {

    id barButtonItem;
    UIActivityIndicatorView *activityIndicator;
    
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhite];
    barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];

    [activityIndicator startAnimating];
    activityIndicator.hidden = NO;
    activityIndicator.hidesWhenStopped = NO;
    
    return barButtonItem;
}

@end
