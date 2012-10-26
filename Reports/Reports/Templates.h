//
//  Templates.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Templates : NSObject

+ (NSArray *)InstalledTemplates;                //Array of NSURLs
+ (NSArray *)ApplicationBundleTemplates;        //Array of NSURLs

+ (void)InstallTemplateNamed:(NSString *)name;  //Name must exist in the app bundle

@end