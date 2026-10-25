//
//  MADDatabaseTableSectionHeaderView.h
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADDatabaseTableSectionHeaderView_h
#define Reports_MADDatabaseTableSectionHeaderView_h

#import <UIKit/UITableViewHeaderFooterView.h>

@protocol MADSectionHeaderViewDelegate;

@interface MADDatabaseTableSectionHeaderView : UITableViewHeaderFooterView

@property (nonatomic, assign) NSInteger section;
@property (nonatomic, weak) id <MADSectionHeaderViewDelegate> delegate;

- (void)setTitle:(NSString *)title;
- (void)toggleOpenWithUserAction:(BOOL)userAction;

@end

#endif
