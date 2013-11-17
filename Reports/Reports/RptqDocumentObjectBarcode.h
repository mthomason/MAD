//
//  RptqDocumentObjectBarcode.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocumentObject, RptqQueryField;

@interface RptqDocumentObjectBarcode : NSManagedObject

@property (nonatomic, retain) NSNumber * add2dComponent;
@property (nonatomic, retain) NSNumber * borderStyle;
@property (nonatomic, retain) NSNumber * borderType;
@property (nonatomic, retain) NSNumber * borderWidth;
@property (nonatomic, retain) NSData * colorBackground;
@property (nonatomic, retain) NSData * colorForeground;
@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSNumber * humanReadable;
@property (nonatomic, retain) NSString * inputField1;
@property (nonatomic, retain) NSString * inputField2;
@property (nonatomic, retain) NSNumber * inputMode;
@property (nonatomic, retain) NSString * inputStatic1;
@property (nonatomic, retain) NSString * inputStatic2;
@property (nonatomic, retain) NSNumber * option1;
@property (nonatomic, retain) NSNumber * option2;
@property (nonatomic, retain) NSNumber * option3;
@property (nonatomic, retain) NSNumber * scale;
@property (nonatomic, retain) NSNumber * showErrorMessage;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSNumber * useStaticInput1;
@property (nonatomic, retain) NSNumber * useStaticInput2;
@property (nonatomic, retain) NSNumber * whitespaceWidth;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) RptqDocumentObject *parentObjectBarcode;
@property (nonatomic, retain) RptqQueryField *referencesField1;
@property (nonatomic, retain) RptqQueryField *referencesField2;

@end
