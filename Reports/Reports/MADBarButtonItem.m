//
//  UIBarButtonItem+ActivityButton.m
//  MAD
//
//  Created by Michael Thomason on 10/2/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADBarButtonItem.h"

const NSInteger MADBarButtonSystemItemActivity = 123321;

@implementation MADBarButtonItem

- (instancetype)initWithBarButtonSystemItem:(UIBarButtonSystemItem)systemItem target:(id)target action:(SEL)action {

    if (systemItem == MADBarButtonSystemItemActivity) {
    
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [activityIndicator startAnimating];
        activityIndicator.hidden = NO;
        activityIndicator.hidesWhenStopped = NO;
        self = [super initWithCustomView: activityIndicator];

    } else {
        
        self = [super initWithBarButtonSystemItem:systemItem target:target action:action];

    }
    
    return self;
}

@end
