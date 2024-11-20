//
//  RptqDocumentElementLabelLink+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqDocumentElementLabelLink.h"

@implementation RptqDocumentElementLabelLink

@end

@implementation RptqDocumentElementLabelLink (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementLabelLink *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocumentElementLabelLink"];
}

@dynamic text;
@dynamic url;

@end
