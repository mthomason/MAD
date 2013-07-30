//
//  RptqDocumentObjectGroupKey+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObjectGroupKey.h"
#import "RptqDocument.h"
#import "RptqDocumentObjectFactory.h"
#import "RptqDocumentObject+Extras.h"

@interface RptqDocumentObjectGroupKey (Extras) <RptqDocumentObjectFactory>

- (NSString *)formattedString:(MTDataType)dataType forValue:(id)value;

@end
