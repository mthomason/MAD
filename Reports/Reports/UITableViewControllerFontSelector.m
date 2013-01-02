//
//  UITableViewControllerFontSelector.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/6/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewControllerFontSelector.h"
#import "MTFont.h"

@interface UITableViewControllerFontSelector()

@end

@implementation UITableViewControllerFontSelector

@synthesize delegate;
@synthesize tableViewCellFontAmericanTypewriter;
@synthesize tableViewCellFontArial;
@synthesize tableViewCellFontCourierNew;
@synthesize tableViewCellFontCourier;
@synthesize tableViewCellFontGeorgia;
@synthesize tableViewCellFontHelvetica;
@synthesize tableViewCellFontHelveticaNeue;
@synthesize tableViewCellFontTimesNewRoman;
@synthesize tableViewCellFontTrebuchet;
@synthesize tableViewCellFontVerdana;
@synthesize tableViewCellFontZapfino;

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self tableView] setDelegate:self];
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
    return YES;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [[[self tableView] cellForRowAtIndexPath:indexPath] retain];

    if ([cell isEqual:[self tableViewCellFontAmericanTypewriter]]) {
        [[self delegate] uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyAmericanTypewriter];
    } else if ([cell isEqual:[self tableViewCellFontArial]]) {
        [[self delegate] uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyArial];
    } else if ([cell isEqual:[self tableViewCellFontCourierNew]]) {
        [[self delegate] uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyCourierNew];
    } else if ([cell isEqual:[self tableViewCellFontCourier]]) {
        [[self delegate] uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyCourier];
    } else if ([cell isEqual:[self tableViewCellFontGeorgia]]) {
        [[self delegate] uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyGeorgia];
    } else if ([cell isEqual:[self tableViewCellFontHelvetica]]) {
        [[self delegate] uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyHelvetica];
    } else if ([cell isEqual:[self tableViewCellFontHelveticaNeue]]) {
        [[self delegate] uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyHelveticaNeue];
    } else if ([cell isEqual:[self tableViewCellFontTimesNewRoman]]) {
        [[self delegate] uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyTimesNewRoman];
    } else if ([cell isEqual:[self tableViewCellFontTrebuchet]]) {
        [[self delegate] uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyTrebuchet];
    } else if ([cell isEqual:[self tableViewCellFontVerdana]]) {
        [[self delegate] uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyVerdana];
    } else if ([cell isEqual:[self tableViewCellFontZapfino]]) {
        [[self delegate] uITableViewControllerDidUpdateFontToFontWithName:MTFontFamilyZapfino];
    }
    
    if ([cell accessoryType] != UITableViewCellAccessoryCheckmark) {
        [[self tableViewCellFontAmericanTypewriter] setAccessoryType:UITableViewCellAccessoryNone];
        [[self tableViewCellFontArial] setAccessoryType:UITableViewCellAccessoryNone];
        [[self tableViewCellFontCourierNew] setAccessoryType:UITableViewCellAccessoryNone];
        [[self tableViewCellFontCourier] setAccessoryType:UITableViewCellAccessoryNone];
        [[self tableViewCellFontGeorgia] setAccessoryType:UITableViewCellAccessoryNone];
        [[self tableViewCellFontHelvetica] setAccessoryType:UITableViewCellAccessoryNone];
        [[self tableViewCellFontHelveticaNeue] setAccessoryType:UITableViewCellAccessoryNone];
        [[self tableViewCellFontTimesNewRoman] setAccessoryType:UITableViewCellAccessoryNone];
        [[self tableViewCellFontTrebuchet] setAccessoryType:UITableViewCellAccessoryNone];
        [[self tableViewCellFontVerdana] setAccessoryType:UITableViewCellAccessoryNone];
        [[self tableViewCellFontZapfino] setAccessoryType:UITableViewCellAccessoryNone];
        
        //Check this box, or not (could test)
        [[[self tableView] cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    
    [[self tableView] deselectRowAtIndexPath:indexPath animated:YES];
    
    [cell release];
    
}

- (void)dealloc {
    [tableViewCellFontAmericanTypewriter release];
    [tableViewCellFontArial release];
    [tableViewCellFontCourierNew release];
    [tableViewCellFontCourier release];
    [tableViewCellFontGeorgia release];
    [tableViewCellFontHelvetica release];
    [tableViewCellFontHelveticaNeue release];
    [tableViewCellFontTimesNewRoman release];
    [tableViewCellFontTrebuchet release];
    [tableViewCellFontVerdana release];
    [tableViewCellFontZapfino release];
    [super dealloc];
}
@end
