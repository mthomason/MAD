//
//  MTViewControllerBarcodeExtraMaxicode.m
//  MAD
//
//  Created by Michael Thomason on 11/12/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTTableViewControllerBarcodeExtraMaxicode.h"
#import "AppDelegate.h"
#import "MTApplicationInstance.h"
#import "MTQuery.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqQueryField.h"

@interface MTTableViewControllerBarcodeExtraMaxicode ()

@end

@implementation MTTableViewControllerBarcodeExtraMaxicode

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSInteger row = [[self delegate] initalEncodingMode];
    UITableViewCell *cell = [[self tableView] cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [[segue destinationViewController] setDelegate:self];
}

#pragma mark - MTQueryBuilderChooseFieldDelegate

- (void)tableViewControllerChooseFieldDidFinish: (MTQueryBuilderChooseFieldViewController *)controller
                                      withField: (RptqQueryField *)field {
    
    [[self navigationController] popViewControllerAnimated:YES];
    
    RptqDatabaseSchemaField *schemaField = [field databaseSchemaField];
    
    MTQuery *querySampleDataField = [[MTQuery alloc] initWithQueryType:MTQueryTypeSampleDataField object:schemaField];
    [querySampleDataField performQuery:^(BOOL success, NSError *error) {
        if (success) {
            [[self delegate] barcodeMaxicodeDidChooseSampleData:[querySampleDataField datatable]];
            [[self tableView] reloadData];
        }
    }];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if ([indexPath section] == 1) {
        NSInteger numberOfRows = [tableView numberOfRowsInSection:1];
        for (NSInteger i = 0; i < numberOfRows; i++) {
            UITableViewCell *c = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:1]];
            [c setAccessoryType:UITableViewCellAccessoryNone];
        }
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        [[self delegate] barcodeMaxicodeDidSetEncodingMode:[cell tag]];
    }
}

@end
