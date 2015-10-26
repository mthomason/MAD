//
//  MADReportLineRepresentation.h
//  MAD Designer
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MADReportLineRepresentation : NSObject

@property (nonatomic, strong, getter=hasText) NSString *text;
@property (nonatomic, assign) Rect frame;

@end
