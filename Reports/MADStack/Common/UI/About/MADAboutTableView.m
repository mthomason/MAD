//
//  MADAboutTableView.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/23/15.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MADAboutTableView.h"
#import <UIKit/UINibLoading.h>

@implementation MADAboutTableView

- (void)awakeFromNib {
    self.backgroundColor = [UIColor whiteColor];
    self.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.estimatedRowHeight = 44.0;
    self.rowHeight = UITableViewAutomaticDimension;
    [super awakeFromNib];
}

@end
