//
//  MADViewControllerBase.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/6/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

- (void)dealloc {
    NSLog(@"\t%s", __PRETTY_FUNCTION__);
}

- (instancetype)init {
    if (self = [super init]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self commonInit];        
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationItem.titleView sizeToFit];
}

- (void)commonInit {
    _firstTimeViewDidAppear = YES;
    _firstTimeViewWillAppear = YES;
    self.viewWillLayoutSubviewsCounter = 0;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    _firstTimeViewWillAppear = NO;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    _firstTimeViewDidAppear = NO;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.viewWillLayoutSubviewsCounter++;
}

- (BOOL)firstTimeViewWillLayoutSubviews {
    return self.viewWillLayoutSubviewsCounter == 1;
}

- (UITabBarItem *)tabBarItem {
    UITabBarItem *tabBarItem = super.tabBarItem;
    if ([self respondsToSelector:@selector(tabBarImage)] && tabBarItem && tabBarItem.image == nil) {
        UIImage *tabBarImage = [self tabBarImage];
        if (tabBarImage) {
            UIImage *tabBarImageOg = [tabBarImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            tabBarItem.image = tabBarImageOg;
            tabBarItem.selectedImage = tabBarImage;
            tabBarItem.title = self.title;
        }
    }
    return tabBarItem;
}

