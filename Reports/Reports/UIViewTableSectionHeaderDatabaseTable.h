//
//  CoreDataTableViewController.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "UIViewGradient.h"
#import "UIColor+EverydayApps.h"

@class UIViewTableSectionHeaderDatabaseTable;

@protocol SectionHeaderViewDelegate <NSObject>
@optional
-(void)sectionHeaderView:(UIViewTableSectionHeaderDatabaseTable*)sectionHeaderView sectionOpened:(NSInteger)section;
-(void)sectionHeaderView:(UIViewTableSectionHeaderDatabaseTable*)sectionHeaderView sectionClosed:(NSInteger)section;
@end

@interface UIViewTableSectionHeaderDatabaseTable : UIViewGradient 

@property (nonatomic, assign) UILabel *titleLabel;
@property (nonatomic, assign) UIButton *disclosureButton;
@property (nonatomic, assign) NSInteger section;
@property (nonatomic, assign) id <SectionHeaderViewDelegate> delegate;

-(id)initWithFrame:(CGRect)frame title:(NSString*)title section:(NSInteger)sectionNumber delegate:(id <SectionHeaderViewDelegate>)delegate;
-(void)toggleOpenWithUserAction:(BOOL)userAction;

@end