//
//  Templates.m
//  Reports
//
//  Created by Michael Thomason on 1/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTReportTemplates.h"
#import "Constants.h"
#import "NSFileManager+Common.h"

@implementation MTReportTemplates

//Array of NSURLs
+ (NSArray *)InstalledTemplates {
    return [NSFileManager contentsOfTemplateDirectoryWithPathExtension: TEMPLATE_PATH_EXTENSION];
}

//Array of NSURLs
+ (NSArray *)ApplicationBundleTemplates {
    return [[[NSArray array] retain] autorelease];
}

//Name must exist in the app bundle
+ (void)InstallTemplateNamed:(NSString *)name {
    
}

@end