//
//  RptqDocumentObjectImage+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObjectImage.h"
#import "MTDatabaseField.h"

@interface RptqDocumentObjectImage (Extras)

- (NSString *)formattedString:(MTDataType)dataType forValue:(id)value;

@end
