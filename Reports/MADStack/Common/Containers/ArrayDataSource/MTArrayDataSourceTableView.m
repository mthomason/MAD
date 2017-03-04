//
//  MTArrayDataSourceTableView.m
//  MAD
//
//  Created by Michael Thomason on 6/14/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MTArrayDataSourceTableView.h"
#import "MTArrayDataSourcePrivate.h"

@implementation MTArrayDataSourceTableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.cellIdentifier
                                                            forIndexPath:indexPath];
    id item = [self itemAtIndexPath:indexPath];
    self.configureCellBlock(cell, item);
    return cell;
}

@end
