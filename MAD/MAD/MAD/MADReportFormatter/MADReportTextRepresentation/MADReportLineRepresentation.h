//
//  MADReportLineRepresentation.h
//  MAD Designer
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIGeometry.h>
#import <MAD/MADDocumentObjectType.h>
#import "MADTextRepresentationProtocol.h"

@interface MADReportLineRepresentation : NSObject
    <MADTextRepresentationProtocol>

    - (instancetype)initWithObject:(id)object type:(MTDocumentObjectType)type frame:(CGRect)frame NS_DESIGNATED_INITIALIZER;

    @property (nonatomic, assign, readonly) CGRect frame;

@end
