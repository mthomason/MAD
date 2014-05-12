//
//  RptqDocumentObjectLabelLink.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocumentObject;

@interface RptqDocumentObjectLabelLink : NSManagedObject

@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) NSString * text;
@property (nonatomic, strong) NSString * url;
@property (nonatomic, strong) RptqDocumentObject *parentObjectLinkLabel;

@end
