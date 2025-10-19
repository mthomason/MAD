//
//  RowTypeDocumentLocal.h
//  MAD
//
//  Created by Michael Thomason on 4/1/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import <WatchKit/WatchKit.h>

@interface MADRowTypeDocumentsLocal : NSObject

@property (weak, nonatomic) IBOutlet WKInterfaceGroup *groupMain;
@property (weak, nonatomic) IBOutlet WKInterfaceImage *image;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *label;

@end
