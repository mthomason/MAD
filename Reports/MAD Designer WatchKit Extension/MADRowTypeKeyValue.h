//
//  MADRowTypeKeyValue.h
//  MAD
//
//  Created by Michael Thomason on 4/5/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface MADRowTypeKeyValue : NSObject

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *labelKey;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *labelValue;

@end
