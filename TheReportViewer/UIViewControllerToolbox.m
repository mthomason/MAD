//
//  labelInformationViewController.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIViewControllerToolbox.h"
#import "UITableViewControllerFontSettings.h"
#import "UITableViewControllerFontSelector.h"

@interface  UIViewControllerToolbox()

@property (retain, nonatomic) NSArray *toolbarItemsPrimary;
@property (retain, nonatomic) NSArray *toolbarItemsSecondary;

@end

@implementation UIViewControllerToolbox

@synthesize delegate;
@synthesize mainScrollView;
@synthesize fontSettingsTableViewController = _fontSettingsTableViewController;
@synthesize uITableViewControllerFontSelector = _uITableViewControllerFontSelector;
@synthesize toolbarItemsPrimary = _toolbarItemsPrimary;
@synthesize toolbarItemsSecondary = _toolbarItemsSecondary;
@synthesize toolbar;

- (void)dealloc {
    [mainScrollView release];
    [_fontSettingsTableViewController release];
    [_uITableViewControllerFontSelector release];
    [_toolbarItemsSecondary release];
    [_toolbarItemsPrimary release];
    [toolbar release];
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
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        
        CGSize contentSize = CGSizeMake([[self view] frame].size.width * 2, [[self mainScrollView] frame].size.height);
        [[self mainScrollView] setContentSize: contentSize];

    }

    //Save off the inital toolbar items
    NSArray *a1 = [[NSArray alloc] initWithArray:[[self toolbar] items]];
    [self setToolbarItemsPrimary:a1];
    [a1 release];
    
    //Save off the toolbar items with a done button
    NSMutableArray *a2 = [[NSMutableArray alloc] initWithArray:[self toolbarItemsPrimary]];
    UIBarItem *backButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneSelectingFont:)];
    [a2 insertObject:backButton atIndex:0];
    [self setToolbarItemsSecondary: a2];
    [backButton release];
    [a2 release];
    
    UIStoryboard *sbFontTableView = [[UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil] retain];
    
    UITableViewControllerFontSettings *tb1 = [[sbFontTableView instantiateViewControllerWithIdentifier:@"FontSettingsTableViewController"] retain];
    [tb1 setDelegate: self];
    [self setFontSettingsTableViewController:tb1];
    [tb1 release];
    
    UITableViewControllerFontSelector *tb2 = [[sbFontTableView instantiateViewControllerWithIdentifier:@"FontListSettingsTableViewController"] retain];
    [tb2 setDelegate: self];
    [self setUITableViewControllerFontSelector:tb2];
    [tb2 release];

    [sbFontTableView release];

}

- (void)viewDidUnload {
    [self setMainScrollView:nil];
    [self setToolbar:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;

    self.fontSettingsTableViewController = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    

    [[[self fontSettingsTableViewController] tableView] setFrame:CGRectMake(CGPointZero.x, CGPointZero.y, [[self mainScrollView] frame].size.width, [[self mainScrollView] frame].size.height)];
    [[[self uITableViewControllerFontSelector] tableView] setFrame:CGRectMake([[self mainScrollView] contentSize].width / 2.0000f, CGPointZero.y, [[self mainScrollView] frame].size.width, [[self mainScrollView] frame].size.height)];
    //[[self mainScrollView] addSubview: [[self fontSettingsTableViewController] tableView]];
    //[[self mainScrollView] addSubview: [[self uITableViewControllerFontSelector] tableView]];

    [[self fontSettingsTableViewController] updateFontSizeDisplay];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //[[[self fontSettingsTableViewController] tableView] removeFromSuperview];
    //[[[self uITableViewControllerFontSelector] tableView] removeFromSuperview];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [self.delegate labelInformationViewControllerDidFinish:self];
}

#pragma - FontSettingsTableViewController Delegate

- (void)fontSettingsTableViewControllerDidSelectFontList:(UITableViewControllerFontSettings *)controller {
    CGPoint newViewPoint = CGPointMake([[self mainScrollView] contentSize].width / 2.0000f, [[self mainScrollView] contentOffset].y);
    CGSize newViewSize = [[self mainScrollView] frame].size;
    CGRect fontList = CGRectMake(newViewPoint.x, newViewPoint.y, newViewSize.width, newViewSize.height);
    [[self mainScrollView] scrollRectToVisible:fontList animated:YES];
    [[self toolbar] setItems:[self toolbarItemsSecondary] animated:YES];
}

- (void)doneSelectingFont:(id)sender {
    CGPoint newViewPoint = CGPointMake(CGPointZero.x, [[self mainScrollView] contentOffset].y);
    CGSize newViewSize = [[self mainScrollView] frame].size;
    CGRect fontList = CGRectMake(newViewPoint.x, newViewPoint.y, newViewSize.width, newViewSize.height);
    [[self mainScrollView] scrollRectToVisible:fontList animated:YES];
    [[self toolbar] setItems:[self toolbarItemsPrimary] animated:YES];
}

#pragma mark -
#pragma mark UITableViewController FontSelector Delegate

- (void)uITableViewControllerDidUpdateFontToFontWithName:(NSString *)fontName {
    [[[self fontSettingsTableViewController] labelFontName] setText:fontName];
}

#pragma - Scroll View Delegates

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    //if (scrollView.contentOffset.x != 0.0000f) {
        //[scrollView setContentOffset:CGPointMake(0.0000f, scrollView.contentOffset.y)];
    //}
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    
    
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    return YES;
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return nil;
}

@end