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
#import "MADSectionHeaderViewDelegate.h"

@class UIViewTableSectionHeaderDatabaseTable;

@interface UIViewTableSectionHeaderDatabaseTable : UIView

- (instancetype)initWithFrame:(CGRect)frame title:(NSString*)title section:(NSInteger)sectionNumber delegate:(id <SectionHeaderViewDelegate>)delegate;
- (void)toggleOpenWithUserAction:(BOOL)userAction;

@end

#endif
