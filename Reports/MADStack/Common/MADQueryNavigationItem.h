//
//  MADQueryNavigationItem.h
//  MAD Designer
//
//  Created by Michael on 2/18/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADQueryNavigationItem_h
#define MAD_MADQueryNavigationItem_h

#import <UIKit/UINavigationBar.h>

@protocol MADQueryNavigationProtocol;

@interface MADQueryNavigationItem : UINavigationItem

    @property (nonatomic, weak) IBOutlet id <MADQueryNavigationProtocol> delegate;

@end

#endif
