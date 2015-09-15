//
//  UIBarButtonItem+Constructors.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 5/29/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIBarButtonItem+Constructors.h"

@implementation UIBarButtonItem (Constructors)

+ (instancetype)buttonEdit:(id)target action:(SEL)action {
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemEdit
                                                                          target: target
                                                                          action: action];
    return edit;
}

+ (instancetype)buttonDuplicate:(id)target action:(SEL)action {
    UIImage *imageDuplcate = [UIImage imageNamed:@"MADImageToolbarDuplicate"];
    UIBarButtonItem *barButtonItemDuplicate = [[UIBarButtonItem alloc] initWithImage: imageDuplcate
                                                                               style: UIBarButtonItemStylePlain
                                                                              target: target
                                                                              action: action];
    barButtonItemDuplicate.enabled = NO;
    return barButtonItemDuplicate;
}

+ (instancetype)buttonEditDone:(id)target action:(SEL)action {
    UIBarButtonItem *barButtonItemEditDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                                           target: target
                                                                                           action: action];
    return barButtonItemEditDone;
}

+ (instancetype)ActivityIndicator {
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhite];
    [activityIndicator startAnimating];
    activityIndicator.hidden = NO;
    activityIndicator.hidesWhenStopped = NO;
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    return barButtonItem;
}

@end
