//
//  MADReportTextRepresentation.h
//  MAD Designer
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MADReportPageRepresentation;

@interface MADReportTextRepresentation : NSObject

@property (nonatomic, strong, getter=hasPages) NSArray <MADReportPageRepresentation *> *pages;

@end
