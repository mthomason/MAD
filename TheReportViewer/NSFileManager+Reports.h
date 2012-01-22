//
//  NSFileManager+Reports.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (Reports)

+ (NSArray *)schemaFiles;
+ (NSArray *)reportFiles;

@end