//
//  MADQueryViewSectionDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/24/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADQueryViewSectionDelegate_h
#define MADQueryViewSectionDelegate_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGBase.h>
#import "MADIdentifierQueryViewSections.h"

@interface MADQueryViewSectionDelegate : NSObject

    - (instancetype)initWithNumberOfTables:(NSUInteger)numberOfTables position:(short)position;
    @property (nonatomic, assign, readonly) MADIdentifierQueryViewSections querySection;
    @property (nonatomic, readonly) NSString   *name;
    @property (nonatomic, readonly) NSUInteger count;
    @property (nonatomic, readonly) NSInteger  numberOfRows;
    @property (nonatomic, readonly) CGFloat    height;
    @property (nonatomic, readonly) SEL        selector;

@end

#endif
