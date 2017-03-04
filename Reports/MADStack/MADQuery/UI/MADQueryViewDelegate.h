//
//  MADQueryViewDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/25/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADQueryViewDelegate_h
#define MAD_Designer_MADQueryViewDelegate_h

#import <UIKit/UITableView.h>
#import "MADIdentifierQueryViewSections.h"

@class MADQueryViewSectionDelegate;
@protocol MADQueryViewControllerLayoutSectionSelectorProtocol;

@protocol MADQueryViewDelegateProtocol <NSObject>

    - (MADIdentifierQueryViewSections)sectionIdentifierForDisplayIndex:(short)displayIndex;
    - (MADQueryViewSectionDelegate *)sectionLayoutForDisplayIndex:(short)displayIndex;
    - (CGFloat)headerHeight;
    - (void)handleUserRequestedSampleDataForTableAtIndex:(NSInteger)index;

@end

@interface MADQueryViewDelegate : NSObject
    <UITableViewDelegate>

    @property (nonatomic, weak) id <MADQueryViewDelegateProtocol, MADQueryViewControllerLayoutSectionSelectorProtocol> delegate;

@end

#endif
