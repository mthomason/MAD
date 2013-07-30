//
//  RptqDocumentObjectImage+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObjectImage.h"
#import "RptqDocument.h"
#import "RptqDocumentObject+Extras.h"

@interface RptqDocumentObjectImage (Extras)

- (NSString *)formattedString:(MTDataType)dataType forValue:(id)value;

@end
