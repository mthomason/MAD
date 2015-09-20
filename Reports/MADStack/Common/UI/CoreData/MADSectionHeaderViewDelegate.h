//
//  MADSectionHeaderViewDelegate.h
//  MAD
//
//  Created by Michael Thomason on 9/28/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADSectionHeaderViewDelegate_h
#define MAD_MADSectionHeaderViewDelegate_h

@class UIViewTableSectionHeaderDatabaseTable;

@protocol SectionHeaderViewDelegate <NSObject>
@optional
- (void)sectionHeaderView: (UIViewTableSectionHeaderDatabaseTable *)sectionHeaderView sectionOpened: (NSInteger)section;
- (void)sectionHeaderView: (UIViewTableSectionHeaderDatabaseTable *)sectionHeaderView sectionClosed: (NSInteger)section;
@end

#endif
