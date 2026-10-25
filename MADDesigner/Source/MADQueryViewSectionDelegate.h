//
//  MADQueryViewSectionDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/24/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADQueryViewSectionDelegate_h
#define MADQueryViewSectionDelegate_h

#import "MADIdentifierQueryViewSections.h"
#import <Foundation/NSObject.h>
#import <CoreGraphics/CGBase.h>

@interface MADQueryViewSectionDelegate : NSObject

- (instancetype)initWithNumberOfTables:(NSUInteger)numberOfTables position:(short)position;
@property (readonly, nonatomic, assign) MADIdentifierQueryViewSections querySection;
@property (readonly, nonatomic, copy) NSString   *name;
@property (readonly, nonatomic, assign) NSUInteger count;
@property (readonly, nonatomic, assign) NSInteger  numberOfRows;
@property (readonly, nonatomic, assign) CGFloat    height;
@property (readonly, nonatomic, assign) SEL        selector;

@end

#endif
