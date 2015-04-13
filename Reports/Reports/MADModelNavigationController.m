//
//  MADModelNavigationController.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/11/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADModelNavigationController.h"

@interface MADModelNavigationController ()

@end

@implementation MADModelNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIBarButtonItem *buttonItemDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButton)];
    buttonItemDone.tintColor = [UIColor redColor];
    self.navigationItem.leftBarButtonItem = buttonItemDone;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    UIBarButtonItem *buttonItemDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButton)];
    buttonItemDone.tintColor = [UIColor redColor];
    self.navigationItem.leftBarButtonItem = buttonItemDone;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [super pushViewController:viewController animated:animated];
    UIBarButtonItem *buttonItemDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButton)];
    buttonItemDone.tintColor = [UIColor redColor];
    self.navigationItem.leftBarButtonItem = buttonItemDone;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIBarButtonItem *buttonItemDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButton)];
    buttonItemDone.tintColor = [UIColor redColor];
    self.navigationItem.rightBarButtonItem = buttonItemDone;

    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
