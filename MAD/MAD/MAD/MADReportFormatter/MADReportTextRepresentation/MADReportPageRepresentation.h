//
//  MADReportPageRepresentation.h
//  MAD Designer
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MADTextRepresentationProtocol.h"

@class MADReportSectionRepresentation;

@interface MADReportPageRepresentation : NSObject
    <MADTextRepresentationProtocol>

    @property (readonly) NSUInteger numberOfSections;

    - (nonnull instancetype)initWithNumberOfSections:(NSUInteger)numberOfSections NS_DESIGNATED_INITIALIZER;
    - (void)addSection:(nonnull MADReportSectionRepresentation *)section;

@end
