//
//  MADTableViewHeader+QueryViewSectionTypes.h
//  MAD Designer
//
//  Created by Michael Thomason on 4/7/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADTableViewHeader.h"

@class MADQueryViewControllerLayoutSection;

@interface MADTableViewHeader (QueryViewSectionTypes)

+ (nonnull instancetype)newTableViewHeaderWithType:(nonnull MADQueryViewControllerLayoutSection *)layout
                                          andFrame:(CGRect)frame
                                            target:(nullable id)target;

@end
