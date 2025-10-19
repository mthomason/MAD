//
//  MADTableViewCellQueryPredicate.h
//  MAD
//
//  Created by Michael Thomason on 2/2/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADTableViewCellQueryPredicate_h
#define Reports_MADTableViewCellQueryPredicate_h

#import "MTAutoLayoutTableViewCell.h"

@class NSManagedObjectID, UILabel;

@interface MADTableViewCellQueryPredicate : MTAutoLayoutTableViewCell

	@property (nonatomic, copy) NSManagedObjectID *predicateID;

	@property (nonatomic, weak) IBOutlet UILabel *labelDetail;
	@property (nonatomic, weak) IBOutlet UILabel *labelMain;
	@property (nonatomic, weak) IBOutlet UILabel *labelOpperator;

@end

#endif
