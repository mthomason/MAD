//
//  ReportDesignerTableViewController.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "ReportDesignerViewController.h"
#import "Constants.h"

@interface ReportDesignerViewController()

@property (assign) BOOL formualInformationViewIsVisable;
@property (assign) BOOL imageInformationViewIsVisable;
@property (assign) BOOL labelInformationViewIsVisable;

@end

@implementation ReportDesignerViewController

@synthesize delegate = _delegate;
@synthesize containerView = _containerView;
@synthesize designScrollView = _designScrollView;
@synthesize informationButton = _informationButton;

@synthesize formualInformationViewIsVisable = _formualInformationViewIsVisable;
@synthesize imageInformationViewIsVisable = _imageInformationViewIsVisable;
@synthesize labelInformationViewIsVisable = _labelInformationViewIsVisable;

- (void)dealloc {
    [_designScrollView release];
    [_containerView release];
    [_informationButton release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload {
    [self setDesignScrollView:nil];
    [self setContainerView:nil];
    [self setInformationButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [self.delegate reportDesignerViewControllerDidFinish:self];
}

- (IBAction)info:(id)sender {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        //Make sure there are no information views open
        
        [[self informationButton] setEnabled: NO];
        
        UIStoryboard *sbLblControl = [[UIStoryboard storyboardWithName:@"ObjectEditFormatStoryboard" bundle:nil] retain];
        EditObjectViewController *lblControl = [[sbLblControl instantiateViewControllerWithIdentifier:@"LabelViewController"] retain];
        //LabelInformationViewController *lblControl = [[[navControl viewControllers] objectAtIndex:0] retain];
        
        //LabelInformationViewController *lblControl = [[LabelInformationViewController alloc] initWithNibName:@"LabelInformationViewController" bundle:nil];
        [sbLblControl release];
        [lblControl setDelegate: self];
        CGRect viewFrame = CGRectMake([self containerView].frame.origin.x, [self containerView].frame.origin.y, [self containerView].frame.size.width, [self view].frame.size.height / 2.0000f);
        CGRect infoViewFrameOnScreen = CGRectMake(viewFrame.origin.x, viewFrame.origin.y + viewFrame.size.height, viewFrame.size.width, viewFrame.size.height);
        CGRect infoViewFrameOffScreen = CGRectMake(viewFrame.origin.x, viewFrame.origin.y + [[self view] frame].size.height, viewFrame.size.width, viewFrame.size.height);
        [[lblControl view] setFrame:infoViewFrameOffScreen];
        [[self view] addSubview:[lblControl view]];
        NSLog(@"ScrolFrame: %@", NSStringFromCGRect([[lblControl view] frame]));
        //NSLog(@"TableFrame: %@", NSStringFromCGRect([v frame]));

        [UIView animateWithDuration: ANIMATION_DURATION_SHOW_FROM_BOTTOM_HALF
                         animations: ^{
                             [[self containerView] setFrame: viewFrame];
                             [[lblControl view] setFrame: infoViewFrameOnScreen];
                         } completion:^(BOOL finished) {
                             
                         }];
        
    } else {
        //UIPopoverController *popControl = [[UIPopoverController alloc] initWithContentViewController:lblControl];
        //[popControl release];
    }
}

#pragma mark -
#pragma mark Delegates

- (void)labelInformationViewControllerDidFinish:(EditObjectViewController *)controller {
    
    CGRect viewFrame = CGRectMake([self containerView].frame.origin.x, [self containerView].frame.origin.y, [self containerView].frame.size.width, [self view].frame.size.height);
    CGRect infoViewFrameOffScreen = CGRectMake(viewFrame.origin.x, viewFrame.origin.y + [[self view] frame].size.height, viewFrame.size.width, viewFrame.size.height);
    
    [UIView animateWithDuration: ANIMATION_DURATION_SHOW_FROM_BOTTOM_HALF
                     animations: ^{
                         [[self containerView] setFrame: viewFrame];
                         [[controller view] setFrame: infoViewFrameOffScreen];
                     } completion:^(BOOL finished) {
                         [[controller view] removeFromSuperview];
                         [controller release];
                         [[self informationButton] setEnabled: YES];
                     }];
    
    
}

#pragma mark -
#pragma mark Table View Data Source Protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

/*
 - (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
 
 }
 */

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {    
    UITableViewCell *result = nil;
    static NSString *MyIdentifier = @"UITableViewCell";
    result = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (result == nil) {
        result = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:MyIdentifier] autorelease];
        result.textLabel.text = @"What up!?!";
    }
    return result;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger numberOfRows;
    switch (section) {
        case 0: {
            numberOfRows = 5;
            break;
        }            
        default:
            numberOfRows = 0;
            break;
    }
	return numberOfRows;
}

/*
 - (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
 
 }
 */

/*
 - (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
 
 }
 */

/*
 - (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
 NSString *result;
 switch (section) {
 case 0:
 result = @"";
 break;
 case 1:
 result = @"";
 break;
 default:
 result = @"";
 break;
 }
 return result;
 }
 */

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}


#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.0000f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat result = 27.0000f;
    return result;
}

/*
 - (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath { }
 */

/*
 - (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section { }
 */

/*
 
 - (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
 
 }
 */

/*
 - (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
 
 }
 */


/*
 - (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

@end
