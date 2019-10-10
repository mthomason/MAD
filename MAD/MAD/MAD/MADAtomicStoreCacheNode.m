//
//  MADAtomicStoreCacheNode.m
//  MAD
//
//  Created by Michael on 4/22/19.
//  Copyright © 2019 Everyday Apps LLC. All rights reserved.
//

#import <CoreData/NSAtomicStore.h>
#import <CoreData/NSAtomicStoreCacheNode.h>
#import "MADAtomicStoreCacheNode.h"

@implementation MADAtomicStoreCacheNode

- (id)initWithObjectID:(NSManagedObjectID *)moid {
    if (nil != (self = [super initWithObjectID:moid])) {
        entityDescription = [[self objectID] entity]; // Don't retain, PSC owns it
    }
    return self;
}

- (NSEntityDescription *)entity {
    return entityDescription;
}

// Check to see if we've unpacked our underlying representation; if not, do
// it now
- (id)valueForKey:(NSString *)key {
    if (nil != propertyDataCache) {
        [self resolvePropertyValues: nil];
    }
    return [super valueForKey:key];
}

- (NSString *)description {
    if (nil != propertyDataCache) {
        return [propertyDataCache description];
    }
    return [[self propertyCache] description];
}

- (void)setPropertyCacheData:(NSDictionary *)dictionary {
    if (propertyDataCache != dictionary) {
        propertyDataCache = dictionary;
    }
}

// Unpack the propertyDataCache and set the propertyCache
- (void)resolvePropertyValues:(NSError **)error {
    NSMutableDictionary *newPropertyCache = [NSMutableDictionary dictionary];
    
    NSAtomicStore *store = (NSAtomicStore *)[[self objectID] persistentStore];
    NSDictionary *storeEntities = [[[store persistentStoreCoordinator] managedObjectModel] entitiesByName];
    
    NSDictionary *attributeDescriptions = [entityDescription attributesByName];
    
    for (NSString *attributeName in attributeDescriptions) {
        id attributeValue = [propertyDataCache valueForKey:attributeName];
        if (nil != attributeValue) {
            NSAttributeDescription *attributeDescription = [attributeDescriptions valueForKey:attributeName];
            if (NSTransformableAttributeType == [attributeDescription attributeType]) {
                NSString *transformerName = [attributeDescription valueTransformerName];
                attributeValue = (nil == transformerName) ? [[NSValueTransformer valueTransformerForName: NSKeyedUnarchiveFromDataTransformerName] transformedValue: attributeValue] : [[NSValueTransformer valueTransformerForName: transformerName] reverseTransformedValue: attributeValue];
            }
            [newPropertyCache setValue: attributeValue forKey:attributeName];
        }
    }
    
    NSDictionary *relationshipDescriptions = [entityDescription relationshipsByName];
    
    for (NSString *relationshipName in relationshipDescriptions) {
        NSArray *rawDestinations = [propertyDataCache valueForKey:relationshipName];
        NSMutableArray *destinationNodes = [NSMutableArray array];
        
        for (NSArray *tuple in rawDestinations) {
            if (0 == [tuple count]) {
                NSLog(@"Bad happened.");
            }
            NSString *destinationEntityName = [tuple objectAtIndex: 0];
            id refdata = [tuple objectAtIndex: 1];
            NSManagedObjectID *oid = [store objectIDForEntity:[storeEntities valueForKey: destinationEntityName] referenceObject:refdata];
            NSAtomicStoreCacheNode *destinationNode = [store cacheNodeForObjectID: oid];
            if (nil == destinationNode) {
                NSLog(@"Referential integrity error. Can't find node for ID: %@", oid);
                if (nil != error) {
                    *error = [NSError errorWithDomain:@"MyAtomicStoreNodes" code:41 userInfo:[NSDictionary dictionaryWithObject:oid forKey:@"badID"]];
                }
                return;
            }
            [destinationNodes addObject: destinationNode];
        }
        if (![[relationshipDescriptions valueForKey: relationshipName] isToMany]) {
            if (0 < [destinationNodes count]) {
                [newPropertyCache setValue: [destinationNodes objectAtIndex:0] forKey:relationshipName];
            }
        } else {
            [newPropertyCache setValue: destinationNodes forKey:relationshipName];
        }
    }
    
    [self setPropertyCache:newPropertyCache];
    [self setPropertyCacheData:nil];
    
}

@end
