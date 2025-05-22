//
//  MNSDatabaseTable.h
//  Reports
//
//  Created by Michael Thomason on 11/18/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADDatabaseTable_h
#define Reports_MADDatabaseTable_h

#import <Foundation/NSObject.h>

@interface MADDatabaseTable : NSObject <NSCopying>

	@property (nonatomic, copy) NSString *name;
	@property (nonatomic, assign) BOOL queryable;

	- (instancetype)initWithTableName:(NSString *)tableName NS_DESIGNATED_INITIALIZER;

@end

#endif
