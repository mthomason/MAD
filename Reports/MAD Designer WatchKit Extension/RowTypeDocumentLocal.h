//
//  RowTypeDocumentLocal.h
//  MAD
//
//  Created by Michael Thomason on 4/1/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

@interface RowTypeDocumentLocal : NSObject

@property (weak, nonatomic) IBOutlet WKInterfaceGroup *groupMain;
@property (weak, nonatomic) IBOutlet WKInterfaceImage *image;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *label;

@end
