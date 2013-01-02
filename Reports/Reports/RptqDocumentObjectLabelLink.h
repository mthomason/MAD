//
//  RptqDocumentObjectLabelLink.h
//  Reports
//
//  Created by Michael Thomason on 1/1/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocumentObject;

@interface RptqDocumentObjectLabelLink : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) RptqDocumentObject *parentObjectLinkLabel;

@end
