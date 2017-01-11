//
//  MADQueryViewDelegate.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryViewDelegate.h"
#import "MADQueryViewSectionDelegate.h"
#import "MADViewTableHeader+QueryViewSectionTypes.h"

CGRect headerSectionFrame(CGFloat);
CGRect headerSectionFrame(CGFloat headerSectionHeight) {
    return CGRectMake(0.0000f, 0.0000f, 320.0000f, headerSectionHeight);
}

@implementation MADQueryViewDelegate

- (void)dealloc {
    if (_delegate) _delegate = nil;
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    id <MADQueryViewDelegateProtocol> delegate = _delegate;
    MADQueryViewSectionDelegate *layout = [delegate sectionLayoutForDisplayIndex:(short)section];
    
    id header = [MADTableViewHeader newTableViewHeaderWithType: layout
                                                      andFrame: headerSectionFrame([delegate headerHeight])
                                                        target: self.delegate];
    return header;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    id <MADQueryViewDelegateProtocol> delegate = _delegate;
    if ([delegate sectionIdentifierForDisplayIndex:(short)indexPath.section] ==
            MADIdentifierQueryViewSectionsTables) {
        [delegate handleUserRequestedSampleDataForTableAtIndex: indexPath.row];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath { }

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath { }

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath { }

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [_delegate headerHeight];
}

- (NSString *)tableView:(UITableView *)tableView
                    titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *title = NSLocalizedString(@"Remove", @"Remove button title.");
    return title;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell
                                         forRowAtIndexPath:(NSIndexPath *)indexPath { }

@end
