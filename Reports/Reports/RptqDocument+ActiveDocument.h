//
//  RptqDocument+ActiveDocument.h
//  Reports
//
//  Created by Michael Thomason on 1/22/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocument.h"
#import "AppDelegate.h"

@interface RptqDocument (ActiveDocument)

+ (NSString *)sqlStatementForActiveDocument;

@end