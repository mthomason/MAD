//
//  UIManagedDocumentMySqlDatabase.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIManagedDocumentMySqlDatabase.h"

@implementation UIManagedDocumentMySqlDatabase

+ (NSString *)persistentStoreName {
    return MYSQLDATABASEDATA_FILENAME;
}

@end