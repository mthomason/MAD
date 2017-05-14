//
//  RptqTextStyle+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqTextStyle+CoreDataProperties.h"

@implementation RptqTextStyle (CoreDataProperties)

+ (NSFetchRequest<RptqTextStyle *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqTextStyle"];
}

@dynamic strikethrough;
@dynamic underline;
@dynamic italic;
@dynamic bold;

@end
