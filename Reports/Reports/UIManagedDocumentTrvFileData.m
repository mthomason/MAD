//
//  UIManagedDocumentTrvFileData.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIManagedDocumentTrvFileData.h"

@implementation UIManagedDocumentTrvFileData

+ (NSString *)persistentStoreName {
    return APPLICATIONDATA_FILENAME;
}

@end