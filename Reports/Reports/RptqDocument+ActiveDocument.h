//
//  RptqDocument+ActiveDocument.h
//  Reports
//
//  Created by Michael Thomason on 1/22/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocument_ActiveDocument_h
#define Reports_RptqDocument_ActiveDocument_h

#import "RptqDocument.h"
#import "AppDelegate.h"

@interface RptqDocument (ActiveDocument)

+ (RptqDocument *)activeDocument;
+ (RptqQuery *)queryForActiveDocument;
+ (NSArray *)queryLinksForActiveDocument;
+ (NSArray *)tablesForActiveDocument;
+ (NSString *)sqlStatementForActiveDocument;

@end

#endif
