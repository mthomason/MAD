//
//  MADReportLineRepresentation.h
//  MAD Designer
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADReportLineRepresentation_h
#define MAD_MADReportLineRepresentation_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGGeometry.h>
#import <MAD/MADDocumentObjectType.h>
#import <MAD/MADReportTextRepresentation.h>

@interface MADReportLineRepresentation : NSObject
	<MADTextRepresentationProtocol>

	- (instancetype)initWithObject:(id)object type:(MADPrintPageElementType)type
							 frame:(CGRect)frame NS_DESIGNATED_INITIALIZER;

	@property (nonatomic, assign, readonly) CGRect frame;

	- (NSString *)label;

@end

#endif
