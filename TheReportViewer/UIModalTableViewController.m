//
//  UIModalTableViewController.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIModalTableViewController.h"


@implementation UIModalTableViewController

@synthesize delegate = _delegate;

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [[self delegate] modalTableViewControllerDidFinish: self];
}


@end