//
//  UITableViewCellInstruction.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITableViewCellInstruction : UITableViewCell

@property (nonatomic, assign) IBOutlet UILabel *labelGroupType;
@property (nonatomic, assign) IBOutlet UILabel *labelGroupTypeDetail;

+ (CGFloat)defaultHeight;

@end