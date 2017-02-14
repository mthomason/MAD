//
//  MADFileExplorerView.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/20/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADExplorerView.h"
#import <UIKit/UIView.h>
#import <UIKit/UITapGestureRecognizer.h>

@implementation MADExplorerView

+ (void)initialize {
    [super initialize];
    if (self == [MADExplorerView self]) {
        @autoreleasepool {
            MADExplorerView *view;
            view = [MADExplorerView appearance];
            view.backgroundColor = [UIColor groupTableViewBackgroundColor];

        }
    }
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.scrollIndicatorInsets = self.contentInset;

    }
    return self;
}

@end
