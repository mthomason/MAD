//
//  RptqQueryLinks+Extras.h
//  TheReportViewer
//
//  Created by Michael Thomason on 3/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryLinks.h"
#import <CoreData/CoreData.h>

@interface RptqQueryLinks (Extras)

+ (void)deleteLinkWithID:(NSManagedObjectID *)objid fromObjectContext:(NSManagedObjectContext *)moc;

@end