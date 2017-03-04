//
//  MADTableViewCellAuto.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/23/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADTableViewCellAuto_h
#define MAD_Designer_MADTableViewCellAuto_h

#import <UIKit/UITableViewCell.h>

@interface MADTableViewCellAuto : UITableViewCell

    @property (nonatomic, strong) UILabel *label;

    @property (nonatomic, strong) NSArray *layoutConstraints;
    @property (atomic, assign) BOOL updatingConstraints;

    - (void)updateConstraints;
    - (void)initialize;

@end

#endif
