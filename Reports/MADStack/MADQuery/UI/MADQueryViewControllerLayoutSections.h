//
//  MADQueryViewControllerLayoutSections.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/24/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADQueryViewControllerLayoutSections_h
#define MADQueryViewControllerLayoutSections_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGBase.h>
#import "MADIdentifierQueryViewSections.h"

@interface MADQueryViewControllerLayoutSection : NSObject

    - (instancetype)initWithNumberOfTables:(NSUInteger)numberOfTables position:(short)position;
    @property (nonatomic, assign, readonly) MADIdentifierQueryViewSections querySection;
    @property (readonly) NSString   *name;
    @property (readonly) NSUInteger count;
    @property (readonly) NSInteger  numberOfRows;
    @property (readonly) CGFloat    height;
    @property (readonly) SEL        selector;

@end

#endif
