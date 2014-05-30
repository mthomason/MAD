//
//  ViewController.m
//  MAD Launch Images
//
//  Created by Michael Thomason on 8/20/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "ViewController.h"
#import "UIColor+EverydayApps.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIColor *barTintColor = [UIColor tintColorBlue];
    [[self navigationController] toolbar] setBarTintColor:barTintColor];
    [[[self navigationController] navigationBar] setTintColor:barTintColor];
}

@end
