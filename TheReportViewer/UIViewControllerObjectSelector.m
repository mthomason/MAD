//
//  UIViewControllerObjectSelector.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/15/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIViewControllerObjectSelector.h"

@interface UIViewControllerObjectSelector ()

@property (retain) UIViewController *visableViewController;

@end

@implementation UIViewControllerObjectSelector

@synthesize delegate;
@synthesize segmentedControlSelectorType;
@synthesize containerView;
@synthesize toolbarMain;
@synthesize navigationBar;
@synthesize navigationItemMain;
@synthesize visableViewController = _visableViewController;
@synthesize managedDocumentQuery = _managedDocumentQuery;

- (void)dealloc {
    if (_managedDocumentQuery) [_managedDocumentQuery release];
    if (_visableViewController) [_visableViewController release];
    [segmentedControlSelectorType release];
    [containerView release];
    
    [toolbarMain release];
    [navigationBar release];
    [navigationItemMain release];
    [super dealloc];
}

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
    [self setContainerView:nil];
    [self setToolbarMain:nil];
    [self setNavigationBar:nil];
    [self setNavigationItemMain:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (void)showObjectSelector {
    UIViewController *hidingView = nil;
    if ([self visableViewController] != nil) {
        hidingView = [[self visableViewController] retain];
    }

    switch ([[self segmentedControlSelectorType] selectedSegmentIndex]) {
        case MNSSegmentedControlOptionsData: {
            [[self navigationItemMain] setPrompt:NSLocalizedString(@"Choose a data field to add to the report.", @"Prompt to choose a data field.")];
            UIStoryboard *sb= [[UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil] retain];
            UITableViewControllerChooseField *tv = [[sb instantiateViewControllerWithIdentifier:@"UITableViewControllerChooseField"] retain];
            [tv setManagedDocumentQuery:[self managedDocumentQuery]];
            [tv setExcludeTables:[NSArray array]];
            [tv setDelegate: self];
            [self setVisableViewController: tv];
            [tv release];
            [sb release];
            
            break;
        }
        case MNSSegmentedControlOptionsMedia: {
            [[self navigationItemMain] setPrompt:NSLocalizedString(@"Choose an image to add to the report.", @"Prompt to choose an image.")];            
            if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypePhotoLibrary]) {
                UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
                [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
                [imagePicker setDelegate: self];
                [self setVisableViewController: imagePicker];
                [imagePicker release];
            }

            break;
        }
        case MNSSegmentedControlOptionsObjects:
            [[self navigationItemMain] setPrompt:NSLocalizedString(@"Choose an object to add to the report.", @"Prompt to choose an object.")];            
            break;
        default:
            break;
    }
    
    
    [[[self visableViewController] view] setFrame:[[self containerView] bounds]];
    [UIView animateWithDuration:0.20000f animations:^{
        if (hidingView) [[hidingView view] removeFromSuperview];
        if ([self visableViewController]) {
            [[self containerView] addSubview:[[self visableViewController] view]];
        }
    } completion:^(BOOL finished) {
        if (hidingView) [hidingView release];
    }];

}

#pragma mark - Actions

- (IBAction)segmentedControlSelectorTypeValueChanged:(id)sender {
    [self showObjectSelector];
}

- (IBAction)done:(id)sender {
    [[self delegate] uIViewControllerObjectSelectorFinish: self];
}

#pragma mark - Delegates

#pragma mark UITableViewControllerChooseFieldDelegate

- (void)tableViewControllerChooseFieldDidFinish:(UITableViewControllerChooseField *)controller withField:(RptqField *)field {
    [[self delegate] didSelectDataField: field];
}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *selectedImage = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!selectedImage) {
        selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    if (selectedImage) {
        [selectedImage retain];

        
        
        [selectedImage release];
    }
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {

}

@end