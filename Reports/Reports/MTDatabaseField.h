//
//  MNSDatabaseField.h
//  Reports
//
//  Created by Michael Thomason on 11/18/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseField_h
#define Reports_MTDatabaseField_h

typedef NS_ENUM(NSUInteger, MTDataType) {
	MTDataTypeString = 0,
	MTDataTypeNumber = 1,
	MTDataTypeImage = 2,
};

#import <Foundation/Foundation.h>

@interface MTDatabaseField : NSObject

- (id)initWithName:(NSString *)name;

@property (nonatomic, retain) NSString *label;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *datatype;

@property (nonatomic, assign) MTDataType fieldType;
@property (nonatomic, assign) NSInteger fieldTypeNative;
@property (nonatomic, assign) NSUInteger width;
@property (nonatomic, assign) NSUInteger decimals;
@property (nonatomic, assign) BOOL primaryKey;

@end

#endif
