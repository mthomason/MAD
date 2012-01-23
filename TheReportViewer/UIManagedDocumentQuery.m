//
//  UIManagedDocumentTrvFileData.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIManagedDocumentQuery.h"
#import "Constants.h"

@implementation UIManagedDocumentQuery

+ (NSString *)persistentStoreName {
    return QUERYDATA_FILENAME;
}

@end