//
//  MTAggregateFunctionsViewController.m
//  Reports
//
//  Created by Michael Thomason on 3/25/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTAggregateFunctionsViewController.h"

NSString * const MTAggregateFunctionsViewControllerIdentifier = @"MTAggregateFunctionsViewControllerIdentifier";

@interface MTAggregateFunctionsViewController ()

@property (nonatomic, retain) IBOutletCollection(UITableViewCell) NSArray *tableViewCells;


@end

@implementation MTAggregateFunctionsViewController


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"MTSegueSelectAggregateFunction"]) {
        UITableViewCell *tableViewCell = (UITableViewCell *)sender;
        [tableViewCell setAccessoryType: UITableViewCellAccessoryCheckmark];
        [self setSelectedFunctionType: [tableViewCell tag]];
    }
}

- (void)dealloc {
    [_tableViewCells release];
    [super dealloc];
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

- (void)setSelectedFunctionType:(MTAggregateFunctionType)selectedFunctionType {
    _selectedFunctionType = selectedFunctionType;
    
    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    dispatch_async(queuePriorityBackground, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            for (UITableViewCell *tableViewCell in [self tableViewCells]) {
                if ([tableViewCell tag] == selectedFunctionType) {
                    [tableViewCell setAccessoryType: UITableViewCellAccessoryCheckmark];
                }
            }
            
        });
    });
    
}


#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self navigationItem] setLeftItemsSupplementBackButton:YES];
    [[self navigationItem] setHidesBackButton:NO];
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
    
    for (UITableViewCell *tableViewCell in [self tableViewCells]) {
        [tableViewCell setAccessoryType: UITableViewCellAccessoryNone];
    }
    
    UITableViewCell *tableViewCell = [[tableView cellForRowAtIndexPath:indexPath] retain];
    [tableViewCell setAccessoryType: UITableViewCellAccessoryCheckmark];
    [self setSelectedFunctionType: [tableViewCell tag]];
    [tableViewCell release];
    
    if ([self delegate] != nil) {
        [[self delegate] didSelectFunction: [self selectedFunctionType]];
    }

}

@end
