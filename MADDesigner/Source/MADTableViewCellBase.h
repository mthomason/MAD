//
//  MADTableViewCellBase.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/23/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADTableViewCellBase_h
#define MAD_Designer_MADTableViewCellBase_h

#import <UIKit/UITableViewCell.h>
#import "MADTableViewCellMargin.h"

@interface MADTableViewCellBase : UITableViewCell

    @property (nonatomic, strong) UILabel *label;
    @property (nonatomic, assign) MADVibrantTableViewCellMarginStyle marginStyle;

    @property (nonatomic, strong) NSArray *layoutConstraints;
    @property (atomic, assign) BOOL updatingConstraints;

    - (void)updateConstraints;
    - (void)initialize;

@end

#endif
