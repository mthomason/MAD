//
//  MADQueryViewControllerLayout.h
//  MAD Designer
//
//  Created by Michael Thomason on 4/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADQueryViewControllerLayoutSection_h
#define MAD_Designer_MADQueryViewControllerLayoutSection_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGBase.h>
#import "MADQueryViewControllerSections.h"

@class NSArray <__covariant ObjectType>;
@class NSSet <__covariant ObjectType>;
@class NSNumber;
@class NSIndexSet;
@class MADQueryViewControllerLayoutSection;

@protocol MADQueryViewControllerLayoutSectionSelectorProtocol;

@interface MADQueryViewControllerLayout : NSObject

    - (instancetype)initWithNumberOfTables:(NSUInteger)numberOfTables reportingEnabled:(BOOL)reportingEnabled;
    @property (nonatomic, readonly, assign) short count;
    @property (nonatomic, readonly, strong) NSArray <__kindof MADQueryViewControllerLayoutSection *> *sections;

    - (NSSet <NSNumber *> *)sectionTypes;
    - (NSIndexSet *)sectionTypesIndexs;
    - (MADQueryViewControllerSections)sectionAtIndex:(short)index;
    - (MADQueryViewControllerLayoutSection *)layoutAtIndex:(short)index;
    
@end

#endif
