//
//  UITableViewControllerSortType.m
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryBuilderSortTypeViewController.h"

#define MNSSortTypeReuseIds [NSArray arrayWithObjects: @"MTTableViewCellSortOrderAccending", @"MTTableViewCellSortOrderDecending", nil]

#define MNSSortTypeNames [NSArray arrayWithObjects: NSLocalizedString(@"Accending", @"Accending"), NSLocalizedString(@"Decending", @"Decending"), nil]

@interface MTQueryBuilderSortTypeViewController ()

@property (weak, nonatomic) IBOutlet UITableViewCell *tableViewCellAccending;
@property (weak, nonatomic) IBOutlet UITableViewCell *tableViewCellDecending;

@end

@implementation MTQueryBuilderSortTypeViewController

@synthesize delegate = _delegate;

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self navigationItem] setLeftItemsSupplementBackButton:YES];
    [[self navigationItem] setHidesBackButton:NO];
    if ([self initalSortOrder] == MNSSortOrderAccending) {
        [[self tableViewCellAccending] setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        [[self tableViewCellDecending] setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:MNSSortTypeReuseIds[MNSSortOrderAccending]]) {
        [self.delegate uITableViewControllerSortTypeDidSelectSortType: MNSSortOrderAccending];
        [[self tableViewCellAccending] setAccessoryType:UITableViewCellAccessoryCheckmark];
        [[self tableViewCellDecending] setAccessoryType:UITableViewCellAccessoryNone];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:MNSSortTypeReuseIds[MNSSortOrderDecending]]) {
        [self.delegate uITableViewControllerSortTypeDidSelectSortType: MNSSortOrderDecending];
        [[self tableViewCellAccending] setAccessoryType:UITableViewCellAccessoryNone];
        [[self tableViewCellDecending] setAccessoryType:UITableViewCellAccessoryCheckmark];

    }
}

@end
