//
//  UITableViewControllerSchemaAddPredicate.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewControllerSchemaAddPredicate.h"


@implementation UITableViewControllerSchemaAddPredicate

@synthesize delegate = _delegate;
@synthesize tableViewCellLeftSide = _tableViewCellLeftSide, tableViewCellRightSide = _tableViewCellRightSide, tableViewCellOperator = _tableViewCellOperator;

- (void)dealloc {
    [_tableViewCellLeftSide release];
    [_tableViewCellRightSide release];
    [_tableViewCellOperator release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) { }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (IBAction)save:(id)sender {
#warning Incomplete save method.
    //[[self delegate] uITableViewControllerSchemaAddPredicateDidAddPredicate:<#(RptqQueryPredicate *)#>];
}

- (IBAction)cancel:(id)sender {
    [[self delegate] uITableViewControllerSchemaAddPredicateDidFinish: self];
}

@end