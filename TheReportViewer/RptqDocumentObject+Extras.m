//
//  RptqDocumentObject+Extras.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObject+Extras.h"

@implementation RptqDocumentObject (Extras)

- (MNSSectionType)getType {
    return [[self type] integerValue];
}

@end