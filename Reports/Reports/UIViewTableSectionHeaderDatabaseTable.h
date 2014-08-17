//
//  CoreDataTableViewController.m
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UIViewTableSectionHeaderDatabaseTable_h
#define Reports_UIViewTableSectionHeaderDatabaseTable_h

#import <Foundation/Foundation.h>
#import "Constants.h"

@class UIViewTableSectionHeaderDatabaseTable;

@protocol SectionHeaderViewDelegate <NSObject>
@optional
- (void)sectionHeaderView:(UIViewTableSectionHeaderDatabaseTable *)sectionHeaderView sectionOpened:(NSInteger)section;
- (void)sectionHeaderView:(UIViewTableSectionHeaderDatabaseTable *)sectionHeaderView sectionClosed:(NSInteger)section;
@end

@interface UIViewTableSectionHeaderDatabaseTable : UIView

- (instancetype)initWithFrame:(CGRect)frame title:(NSString*)title section:(NSInteger)sectionNumber delegate:(id <SectionHeaderViewDelegate>)delegate NS_DESIGNATED_INITIALIZER;
- (void)toggleOpenWithUserAction:(BOOL)userAction;

@end

#endif
