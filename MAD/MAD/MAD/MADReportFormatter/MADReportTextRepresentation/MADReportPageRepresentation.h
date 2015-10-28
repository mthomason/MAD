//
//  MADReportPageRepresentation.h
//  MAD Designer
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MADReportLineRepresentation;

@interface MADReportPageRepresentation : NSObject

@property (nonatomic, strong, getter=hasLines) NSArray <__kindof MADReportLineRepresentation *> *lines;

@end
