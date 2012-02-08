//
//  CoreDataTableViewController.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>
#import "UIViewSectionHeaderTable.h"

@interface UITableViewControllerDataFieldSelector : UITableViewController <MFMailComposeViewControllerDelegate, SectionHeaderViewDelegate> 

@property (nonatomic, retain) NSArray* dataTables;
@property (nonatomic, assign) IBOutlet UITableViewCell *fieldCells;

@end