//
//  UIManagedDocumentMySqlDatabase.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UIManagedDocumentMySqlDatabase.h"
#import "Constants.h"

@implementation UIManagedDocumentMySqlDatabase

+ (NSString *)persistentStoreName {
    return MYSQLDATABASEDATA_FILENAME;
}

@end