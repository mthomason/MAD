//
//  MTViewTableHeader+QueryViewSectionTypes.h
//  MAD Designer
//
//  Created by Michael Thomason on 4/7/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MTViewTableHeader.h"

@class MADQueryViewControllerLayoutSection;

@interface MTViewTableHeader (QueryViewSectionTypes)

+ (nonnull instancetype)newTableViewHeaderWithType:(nonnull MADQueryViewControllerLayoutSection *)layout andFrame:(CGRect)frame
                                            target:(nullable id)target;

@end
