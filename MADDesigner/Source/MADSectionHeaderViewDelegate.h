//
//  MADSectionHeaderViewDelegate.h
//  MAD
//
//  Created by Michael Thomason on 9/28/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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
