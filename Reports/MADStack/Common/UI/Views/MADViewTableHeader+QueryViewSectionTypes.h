//
//  MADTableViewHeader+QueryViewSectionTypes.h
//  MAD Designer
//
//  Created by Michael Thomason on 4/7/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADTableViewHeader_h
#define MAD_Designer_MADTableViewHeader_h

#import "MADTableViewHeader.h"

@class MADQueryViewSectionDelegate;

@protocol MADQueryViewControllerLayoutSectionSelectorProtocol;

@interface MADTableViewHeader (QueryViewSectionTypes)

    + (nonnull instancetype)newTableViewHeaderWithType:(nonnull MADQueryViewSectionDelegate *)layout
                                              andFrame:(CGRect)frame
                                                target:(nullable id <MADQueryViewControllerLayoutSectionSelectorProtocol>)target;

@end

#endif
