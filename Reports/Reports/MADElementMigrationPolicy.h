//
//  MADElementDropPointMigrationPolicy.h
//  MAD Designer
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface MADElementDropPointMigrationPolicy : NSEntityMigrationPolicy

- (NSValue *)migrateValueFromDropPointX:(NSNumber *)dropPointX dropPointY:(NSNumber *)dropPointY;

@end
