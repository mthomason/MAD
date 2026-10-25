//
//  MADSectionHeaderViewDelegate.h
//  MAD
//
//  Created by Michael Thomason on 9/28/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADSectionHeaderViewDelegate_h
#define MAD_MADSectionHeaderViewDelegate_h

@class MADDatabaseTableSectionHeaderView;

@protocol MADSectionHeaderViewDelegate <NSObject>
  @optional
    - (void)sectionHeaderView: (MADDatabaseTableSectionHeaderView *)sectionHeaderView sectionOpened: (NSInteger)section;
    - (void)sectionHeaderView: (MADDatabaseTableSectionHeaderView *)sectionHeaderView sectionClosed: (NSInteger)section;
@end

#endif
