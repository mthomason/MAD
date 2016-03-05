//
//  UIBarButtonItem+Constructors.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 5/29/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIBarButtonItem+Constructors.h"

@implementation MADBarButtonItemCustom

+ (instancetype)newBarButtonItemEdit:(id)target action:(SEL)action NS_RETURNS_RETAINED {
    MADBarButtonItemCustom *edit = [[self alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemEdit
                                                                target: target
                                                                action: action];
    return edit;
}

+ (instancetype)newBarButtonItemDuplicate:(id)target action:(SEL)action NS_RETURNS_RETAINED {
    UIImage *imageDuplcate = [UIImage imageNamed:@"MADImageToolbarDuplicate"];
    MADBarButtonItemCustom *barButtonItemDuplicate = [[self alloc] initWithImage: imageDuplcate
                                                                     style: UIBarButtonItemStylePlain
                                                                    target: target
                                                                    action: action];
    barButtonItemDuplicate.enabled = NO;
    return barButtonItemDuplicate;
}

+ (instancetype)newBarButtonItemEditDone:(id)target action:(SEL)action NS_RETURNS_RETAINED {
    MADBarButtonItemCustom *barButtonItemEditDone = [[self alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                                           target: target
                                                                                           action: action];
    return barButtonItemEditDone;
}

+ (instancetype)newBarButtonItemActivityIndicator NS_RETURNS_RETAINED {
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhite];
    [activityIndicator startAnimating];
    activityIndicator.hidden = NO;
    activityIndicator.hidesWhenStopped = NO;
    MADBarButtonItemCustom *barButtonItem = [[self alloc] initWithCustomView:activityIndicator];
    return barButtonItem;
}

@end
