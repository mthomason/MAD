//
//  MADFontPickerNavigationController.m
//  MAD
//
//  Created by Michael Thomason on 10/30/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADFontPickerNavigationController.h"

@implementation MADFontPickerNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationBar.translucent = YES;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    //self.navigationBar.frame = CGRectMake(CGPointZero.x, CGPointZero.y + self.topLayoutGuide.length, self.navigationBar.bounds.size.width, self.navigationBar.bounds.size.height);
}

@end
