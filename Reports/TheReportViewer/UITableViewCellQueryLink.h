//
//  UITableViewCellQueryLink.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/23/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface UITableViewCellQueryLink : UITableViewCell

@property (retain) NSManagedObjectID *tableID;

@property (nonatomic, assign) IBOutlet UILabel *labelTableLeft;
@property (nonatomic, assign) IBOutlet UILabel *labelTableRight;
@property (nonatomic, assign) IBOutlet UILabel *labelFieldLeft;
@property (nonatomic, assign) IBOutlet UILabel *labelFieldRight;
@property (nonatomic, assign) IBOutlet UILabel *labelJoinArrow;
@property (nonatomic, assign) IBOutlet UILabel *labelJoinDesc;

+ (CGFloat)defaultHeight;

@end