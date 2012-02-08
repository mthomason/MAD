//
//  CoreDataTableViewController.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SectionHeaderViewDelegate;


@interface UIViewSectionHeaderTable : UIView 

@property (nonatomic, assign) UILabel *titleLabel;
@property (nonatomic, assign) UIButton *disclosureButton;
@property (nonatomic, assign) NSInteger section;
@property (nonatomic, assign) id <SectionHeaderViewDelegate> delegate;

-(id)initWithFrame:(CGRect)frame title:(NSString*)title section:(NSInteger)sectionNumber delegate:(id <SectionHeaderViewDelegate>)delegate;
-(void)toggleOpenWithUserAction:(BOOL)userAction;

@end



/*
 Protocol to be adopted by the section header's delegate; the section header tells its delegate when the section should be opened and closed.
 */
@protocol SectionHeaderViewDelegate <NSObject>

@optional
-(void)sectionHeaderView:(UIViewSectionHeaderTable*)sectionHeaderView sectionOpened:(NSInteger)section;
-(void)sectionHeaderView:(UIViewSectionHeaderTable*)sectionHeaderView sectionClosed:(NSInteger)section;

@end

