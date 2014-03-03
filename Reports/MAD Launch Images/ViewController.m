//
//  ViewController.m
//  MAD Launch Images
//
//  Created by Michael Thomason on 8/20/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "ViewController.h"
#import "UIColor+EverydayApps.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIColor *barTintColor = [UIColor tintColor];
    UIToolbar *toolbar = [[self navigationController] toolbar];
    [toolbar setBarTintColor:barTintColor];
    [[[self navigationController] navigationBar] setTintColor:barTintColor];
	// Do any additional setup after loading the view, typically from a nib.
}

@end
