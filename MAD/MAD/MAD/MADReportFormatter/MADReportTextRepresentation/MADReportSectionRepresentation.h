//
//  MADReportSectionRepresentation.h
//  MAD
//
//  Created by Michael Thomason on 10/29/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADReportSectionRepresentation_h
#define MAD_MADReportSectionRepresentation_h

#import <Foundation/NSObject.h>
#import <MAD/MADDocumentTextRepresentationProtocol.h>
#import <MAD/MADocumentSectionType.h>

@class MADReportSectionRowsRepresentation;

@interface MADReportSectionRepresentation : NSObject
	<MADTextRepresentationProtocol>

	@property (readonly) NSUInteger numberOfRows;
	@property (nonatomic, assign, getter=isVisibile) BOOL visibility;
	@property (nonatomic, assign) MADDocumentSectionType type;

	- (nonnull instancetype)initWithNumberOfRows:(NSUInteger)capacity NS_DESIGNATED_INITIALIZER;
	- (BOOL)addRow:(nonnull MADReportSectionRowsRepresentation *)row
			 error:(NSError * __nullable __autoreleasing * __nullable)error;

@end

#endif
