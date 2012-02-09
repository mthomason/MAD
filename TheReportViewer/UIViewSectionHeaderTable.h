//
//  CoreDataTableViewController.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@class UIViewSectionHeaderTable;

@protocol SectionHeaderViewDelegate <NSObject>

@optional
-(void)sectionHeaderView:(UIViewSectionHeaderTable*)sectionHeaderView sectionOpened:(NSInteger)section;
-(void)sectionHeaderView:(UIViewSectionHeaderTable*)sectionHeaderView sectionClosed:(NSInteger)section;

@end

@interface UIViewSectionHeaderTable : UIView 

@property (nonatomic, assign) UILabel *titleLabel;
@property (nonatomic, assign) UIButton *disclosureButton;
@property (nonatomic, assign) NSInteger section;
@property (nonatomic, assign) id <SectionHeaderViewDelegate> delegate;

-(id)initWithFrame:(CGRect)frame title:(NSString*)title section:(NSInteger)sectionNumber delegate:(id <SectionHeaderViewDelegate>)delegate;
-(void)toggleOpenWithUserAction:(BOOL)userAction;

@end