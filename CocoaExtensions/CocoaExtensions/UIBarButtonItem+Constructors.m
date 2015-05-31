//
//  UIBarButtonItem+Constructors.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 5/29/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIBarButtonItem+Constructors.h"

@implementation UIBarButtonItem (Constructors)

+ (UIBarButtonItem *)buttonEdit:(id)target action:(SEL)action {
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemEdit
                                                                          target: target
                                                                          action: action];
    return edit;
}

+ (UIBarButtonItem *)buttonDuplicate:(id)target action:(SEL)action {
    UIImage *imageDuplcate = [UIImage imageNamed:@"MADImageToolbarDuplicate"];
    UIBarButtonItem *barButtonItemDuplicate = [[UIBarButtonItem alloc] initWithImage: imageDuplcate
                                                                               style: UIBarButtonItemStylePlain
                                                                              target: target
                                                                              action: action];
    barButtonItemDuplicate.enabled = NO;
    return barButtonItemDuplicate;
}

+ (UIBarButtonItem *)buttonEditDone:(id)target action:(SEL)action {
    UIBarButtonItem *barButtonItemEditDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                                           target: target
                                                                                           action: action];
    return barButtonItemEditDone;
}

@end
