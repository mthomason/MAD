//
//  MADViewTableHeader.h
//  Reports
//
//  Created by Michael Thomason on 1/27/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADViewTableHeader_h
#define Reports_MADViewTableHeader_h

#import <UIKit/UIView.h>

@class UIButton, UILabel, MADQueryViewSectionDelegate;

@protocol MADQueryViewControllerLayoutSectionSelectorProtocol;


@interface MADTableViewHeader : UIView

    + (instancetype)newTableViewHeaderWithType:(MADQueryViewSectionDelegate *)layout
                                      andFrame:(CGRect)frame
                                        target:(id <MADQueryViewControllerLayoutSectionSelectorProtocol>)target;

    @property (nonatomic, weak) IBOutlet UIButton *buttonAdd;
    @property (nonatomic, weak) IBOutlet UILabel *labelTitle;

@end

#endif
