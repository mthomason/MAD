//
//  MADSplitViewContainer.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/21/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MADocumentProtocol.h"
#import "MUIViewControllerDelegate.h"

@interface MADSplitViewContainer : UIViewController
    <MADocumentProtocol>

@property (nonatomic, weak) id <MTViewControllerProtocol> viewControllerDelegate;

@end
