//
//  RptqDocumentSection.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/11/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocument, RptqDocumentObject, RptqQueryGroup;

@interface RptqDocumentSection : NSManagedObject

@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) RptqDocument *inReport;
@property (nonatomic, retain) NSSet *hasObjects;
@property (nonatomic, retain) RptqQueryGroup *inGroup;
@end

@interface RptqDocumentSection (CoreDataGeneratedAccessors)

- (void)addHasObjectsObject:(RptqDocumentObject *)value;
- (void)removeHasObjectsObject:(RptqDocumentObject *)value;
- (void)addHasObjects:(NSSet *)values;
- (void)removeHasObjects:(NSSet *)values;

@end
