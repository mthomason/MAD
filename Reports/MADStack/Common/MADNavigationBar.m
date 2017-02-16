//
//  MADNavigationBar.m
//  MAD Designer
//
//  Created by Michael on 2/16/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADNavigationBar.h"

@implementation MADNavigationBar

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.topItem.titleView sizeToFit];
}

@end
