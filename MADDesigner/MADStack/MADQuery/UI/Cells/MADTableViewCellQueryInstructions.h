//
//  UITableViewCellInstruction.h
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#ifndef Reports_UITableViewCellInstruction_h
#define Reports_UITableViewCellInstruction_h

#import "MTAutoLayoutTableViewCell.h"

@class NSManagedObjectID, UILabel;

@interface MADTableViewCellQueryInstructions : MTAutoLayoutTableViewCell

	@property (nonatomic, weak) IBOutlet UILabel *labelGroupType;
	@property (nonatomic, weak) IBOutlet UILabel *labelGroupTypeDetail;

	- (instancetype)initWithCoder:(NSCoder *)aDecoder;
	- (instancetype)initWithStyle:(UITableViewCellStyle)style
				  reuseIdentifier:(NSString *)reuseIdentifier;
	+ (CGFloat)defaultHeight;

@end

#endif
