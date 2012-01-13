//
//  UITableViewControllerDataSourceTypes.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UITableViewControllerDataSourceTypes.h"

@implementation UITableViewControllerDataSourceTypes

@synthesize delegate;

- (IBAction)done:(id)sender {
    [[self delegate] uITableViewControllerDataSourceTypesDidFinish:self];
}

@end