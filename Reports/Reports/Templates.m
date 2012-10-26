//
//  Templates.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "Templates.h"
#import "Constants.h"
#import "NSFileManager+Common.h"

@implementation Templates

//Array of NSURLs
+ (NSArray *)InstalledTemplates {
    return [NSFileManager contentsOfTemplateDirectoryWithPathExtension: TEMPLATE_PATH_EXTENSION];
}

//Array of NSURLs
+ (NSArray *)ApplicationBundleTemplates {
    
}

//Name must exist in the app bundle
+ (void)InstallTemplateNamed:(NSString *)name {
    
}

@end