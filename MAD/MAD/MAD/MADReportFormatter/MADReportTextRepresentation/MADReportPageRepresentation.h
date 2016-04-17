//
//  MADReportPageRepresentation.h
//  MAD Designer
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADReportPageRepresentation_h
#define MAD_MADReportPageRepresentation_h

#import <Foundation/NSObject.h>
#import <MAD/MADReportTextRepresentation.h>

@class NSMutableArray;
@class MADReportSectionRepresentation;

@interface MADReportPageRepresentation : NSObject
    <MADTextRepresentationProtocol>

    @property (readonly) NSUInteger numberOfSections;
    @property (nonatomic, strong, getter=hasSections, readonly) NSMutableArray <__kindof MADReportSectionRepresentation *> *sections;

    - (nonnull instancetype)initWithNumberOfSections:(NSUInteger)numberOfSections NS_DESIGNATED_INITIALIZER;
    - (void)addSection:(nonnull MADReportSectionRepresentation *)section;

@end

#endif
