//
//  NSFileManager-Common.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

@interface NSFileManager (Common)

+ (NSMutableArray *)contentsOfDocumentsDirectory;
+ (NSArray *)contentsOfPrivateDirectory;
+ (NSString *)applicationDocumentsDirectory;
+ (NSString *)applicationPrivateDocumentsDirectory;

@end