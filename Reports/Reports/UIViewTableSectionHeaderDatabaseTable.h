//
//  CoreDataTableViewController.m
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
//#import "MTGradientView.h"
#import "UIColor+EverydayApps.h"

@class UIViewTableSectionHeaderDatabaseTable;

@protocol SectionHeaderViewDelegate <NSObject>
@optional
-(void)sectionHeaderView:(UIViewTableSectionHeaderDatabaseTable *)sectionHeaderView sectionOpened:(NSInteger)section;
-(void)sectionHeaderView:(UIViewTableSectionHeaderDatabaseTable *)sectionHeaderView sectionClosed:(NSInteger)section;
@end

@interface UIViewTableSectionHeaderDatabaseTable : UIView

-(id)initWithFrame:(CGRect)frame title:(NSString*)title section:(NSInteger)sectionNumber delegate:(id <SectionHeaderViewDelegate>)delegate;
-(void)toggleOpenWithUserAction:(BOOL)userAction;

@end
