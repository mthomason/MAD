//
//  UIViewControllerSettings.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIViewControllerSettings.h"

@implementation UIViewControllerSettings

- (void)dealloc {
    [_tableViewControllerSettings release];
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    UIStoryboard *sb= [[UIStoryboard storyboardWithName:STORYBOARD_NAME() bundle:nil] retain];
    UITableViewControllerSettings *tb1 = [[sb instantiateViewControllerWithIdentifier:@"UITableViewControllerSettings"] retain];
    [self setTableViewControllerSettings: tb1];
    [tb1 release];
    [sb release];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[self view] addSubview: [[self tableViewControllerSettings] tableView]];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[[self tableViewControllerSettings] tableView] removeFromSuperview];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [[self delegate] viewControllerDidFinish:self];
}

@end