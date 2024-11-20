//
//  MTTableViewControllerBarcodeExtraDataMatrix.m
//  MAD
//
//  Created by Michael Thomason on 11/15/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTTableViewControllerBarcodeExtraDataMatrix.h"

@interface MTTableViewControllerBarcodeExtraDataMatrix ()

@end

@implementation MTTableViewControllerBarcodeExtraDataMatrix

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSInteger row = [self.delegate barcodeDataMatrixInitalSize];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:1]];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    id <MTTableViewControllerBarcodeExtraDataMatrixDelegate> delegate;
    delegate = self.delegate;
    
    NSInteger section = indexPath.section;
    switch (indexPath.section) {
        case 0: {
            BOOL suppress = [delegate barcodeDataMatrixSuppressRectangularSymbols] == NO;
            UITableViewCell *c = [tableView cellForRowAtIndexPath:indexPath];
            UITableViewCellAccessoryType accessory = suppress ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            c.accessoryType = accessory;
            [delegate barcodeDataMatrixDidSuppressRectangularSymbols:suppress];
            break;
        }
        case 1: {
            NSInteger numberOfRows = [tableView numberOfRowsInSection:section];
            for (NSInteger i = 0; i < numberOfRows; i++) {
                UITableViewCell *c = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section]];
                c.accessoryType = UITableViewCellAccessoryNone;
            }
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [delegate barcodeDataMatrixDidSelectSize:cell.tag];

            break;
        }
        default:
            break;
    }
}

@end
