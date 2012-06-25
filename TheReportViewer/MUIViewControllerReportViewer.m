//
//  MUIViewControllerReportViewer.m
//  TheReportViewer
//
//  Created by Michael Thomason on 3/1/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MUIViewControllerReportViewer.h"

@interface MUIViewControllerReportViewer ()

@end

@implementation MUIViewControllerReportViewer

@synthesize delegate = _delegate;
@synthesize managedDocumentQuery = _managedDocumentQuery;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)done:(id)sender {
    [[self delegate] viewControllerReportViewerDidFinish: self];
}

@end