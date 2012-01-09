//
//  UIViewControllerSettings.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UIViewControllerSettings.h"
#import "UITableViewControllerSettings.h"

@implementation UIViewControllerSettings

@synthesize delegate;
@synthesize tableViewControllerSettings = _tableViewControllerSettings;

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

    UIStoryboard *sb= [[UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil] retain];
    UITableViewControllerSettings *tb1 = [[sb instantiateViewControllerWithIdentifier:@"UITableViewControllerSettings"] retain];
    [self setTableViewControllerSettings: tb1];
    [tb1 release];
    [sb release];

}

- (void)viewDidUnload {
    [self setTableViewControllerSettings: nil];
    [super viewDidUnload];
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [self.delegate uIViewControllerSettingsDidFinish:self];
}

@end