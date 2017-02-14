//
//  MADExplorerActivityIndicator.m
//  MADExplorer
//
//  Created by Michael on 2/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADExplorerActivityIndicator.h"

@implementation MADExplorerActivityIndicator

+ (instancetype)newExplorerActivityIndicator {
    id activityIndicatorView;
    activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
                             UIActivityIndicatorViewStyleGray];
    [activityIndicatorView stopAnimating];
    [activityIndicatorView setAutoresizingMask: UIViewAutoresizingFlexibleLeftMargin |
                                                UIViewAutoresizingFlexibleRightMargin |
                                                UIViewAutoresizingFlexibleTopMargin |
                                                UIViewAutoresizingFlexibleBottomMargin];
    [activityIndicatorView setTranslatesAutoresizingMaskIntoConstraints: YES];
    return activityIndicatorView;
}

@end
