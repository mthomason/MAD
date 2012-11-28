//
//  UIManagedDocumentTrvFileData.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIManagedDocumentPreferencesUser.h"

@implementation UIManagedDocumentPreferencesUser

+ (NSString *)persistentStoreName {
    return TRVDATA_FILENAME;
}

@end