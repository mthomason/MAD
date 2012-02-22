//
//  UIViewControllerObjectSelector.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/15/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIViewControllerObjectSelector.h"

@implementation UIViewControllerObjectSelector

@synthesize delegate;
@synthesize segmentedControlSelectorType;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    BOOL imagePickerAvailable = [UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypePhotoLibrary];
    
    [[self segmentedControlSelectorType] setSelectedSegmentIndex: MNSSegmentedControlOptionsData];

    [[self segmentedControlSelectorType] setEnabled: imagePickerAvailable
                                  forSegmentAtIndex: MNSSegmentedControlOptionsMedia];
    [[self segmentedControlSelectorType] setEnabled: YES
                                  forSegmentAtIndex: MNSSegmentedControlOptionsData];
    [[self segmentedControlSelectorType] setEnabled: YES
                                  forSegmentAtIndex: MNSSegmentedControlOptionsObjects];
    [self showObjectSelector];
}

- (void)viewDidUnload {
    [self setSegmentedControlSelectorType:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (void)showObjectSelector {
    switch ([[self segmentedControlSelectorType] selectedSegmentIndex]) {
        case MNSSegmentedControlOptionsData:
            
            break;
        case MNSSegmentedControlOptionsMedia:
            
            break;
        case MNSSegmentedControlOptionsObjects:

            break;
        default:
            break;
    }
}

- (IBAction)segmentedControlSelectorTypeValueChanged:(id)sender {
    [self showObjectSelector];
}

- (IBAction)done:(id)sender {
    [[self delegate] uIViewControllerObjectSelectorFinish: self];
}

- (void)dealloc {
    [segmentedControlSelectorType release];
    [super dealloc];
}
@end