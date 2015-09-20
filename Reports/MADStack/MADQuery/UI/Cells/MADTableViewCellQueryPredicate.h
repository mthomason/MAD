//
//  MADTableViewCellQueryPredicate.h
//  MAD
//
//  Created by Michael Thomason on 2/2/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADTableViewCellQueryPredicate_h
#define Reports_MADTableViewCellQueryPredicate_h

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "MTAutoLayoutTableViewCell.h"

@interface MADTableViewCellQueryPredicate : MTAutoLayoutTableViewCell

@property (retain) NSManagedObjectID *tableID;

@property (nonatomic, weak) IBOutlet UILabel *labelDetail;
@property (nonatomic, weak) IBOutlet UILabel *labelMain;
@property (nonatomic, weak) IBOutlet UILabel *labelOpperator;

@end

#endif
