//
//  MTQueryBuilderContainerController.m
//  MTQueryBuilderContainerController
//
//  Created by Michael Thomason on 2/13/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryBuilderContainerController.h"
#import <CoreData/CoreData.h>

#import "MTApplicationInstance.h"
#import "MADDesignerViewController.h"
#import "MADQueryViewController.h"
#import "MADQueryVisualizationViewController.h"

#import "UIDevice+Hack.h"
#import "MTStoreKitController+NonRenewableLicensing.h"

#import "UIViewController+ui.h"
#import "MTShowSqlViewController.h"

@interface MTQueryBuilderContainerController ()
    <UIPopoverControllerDelegate>

@property (nonatomic, strong) IBOutlet UIView *leftView;
@property (nonatomic, strong) IBOutlet UIView *rightView;
@property (nonatomic, strong) IBOutletCollection(NSLayoutConstraint) NSArray *bogusConstraints;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *barButtonItemEdit;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *barButtonItemRevealQuery;

@property (nonatomic, strong) NSArray *constraintsViewWillAppear;

@property (nonatomic, strong) UIPopoverController *popover;

@property (nonatomic, assign) BOOL isEditing;

@end

@implementation MTQueryBuilderContainerController

- (NSString *)title {
    return NSLocalizedString(@"MAD Query", "MAD Query");
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        UILabel *labelMadDesigner = [[UILabel alloc] initWithFrame:CGRectZero];
        labelMadDesigner.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        NSAttributedString *attributedString = [MTApplicationInstance localizedAttributedApplicationNameMadQuery];
        [labelMadDesigner setAttributedText:attributedString];
        [self.navigationItem setTitleView:labelMadDesigner];
        [[self.navigationItem titleView] sizeToFit];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setIsEditing:NO];
    
    [self.view removeConstraints:[self bogusConstraints]];
    
    UIView *leftView = [self leftView];
    UIView *rightView = [self rightView];
    NSString *constraintAsciiArtHorizontal = @"H:|-(==0.0000)-[leftView(==320.0000)]-(==0.0000)-[rightView]-(==0.0000)-|";
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(leftView, rightView);
    NSArray *constraintsHorizontal = [NSLayoutConstraint constraintsWithVisualFormat:constraintAsciiArtHorizontal
                                                                             options:0
                                                                             metrics:nil
                                                                               views:viewsDictionary];
    [self setConstraintsViewWillAppear:constraintsHorizontal];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [[self.navigationItem titleView] sizeToFit];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    __block MTQueryBuilderContainerController *blockSelf = self;
    [[MTStoreKitController sharedObject] licensedUser:^(BOOL isLicensedUser, NSDate *experationDate) {
        if (isLicensedUser == NO) {
            NSArray *items = [self toolbarItems];
            NSMutableArray *mutableItems = [items mutableCopy];
            [mutableItems removeObject:[blockSelf barButtonItemRevealQuery]];
            [blockSelf setToolbarItems:mutableItems];
            blockSelf = nil;
        }
    }];
    
    [self.view addConstraints:[self constraintsViewWillAppear]];
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.view removeConstraints:[self constraintsViewWillAppear]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:MNSSegueShowSql]) {
        if ([UIDevice isPad]) { //iPhone version handled in MADQueryViewController
            UIPopoverController *popoverController = [(UIStoryboardPopoverSegue *)segue popoverController];
            [popoverController setDelegate:self];
            self.popover = popoverController;
            UINavigationController *navController = (UINavigationController *)popoverController.contentViewController;
            MTShowSqlViewController *showSqlViewController = (MTShowSqlViewController *)navController.topViewController;
            showSqlViewController.query = self.document.defaultQuery;
            [self disableTabBarItems];
        }
        
    } else if (sender == self) {
        [segue.destinationViewController setDocument:self.document];
        [segue.destinationViewController reloadDocument:self.document animated:YES];
    } else {
        if ([self popover] != nil) {
            if ([[self popover] isPopoverVisible]) {
                [[self popover] dismissPopoverAnimated:YES];
            }
        }
        Class popoverSegueClass = [UIStoryboardPopoverSegue class];
        if ([segue isKindOfClass:popoverSegueClass]) {
            [[(UIStoryboardPopoverSegue *)segue popoverController] setDelegate:self];
            [self setPopover:[(UIStoryboardPopoverSegue *)segue popoverController]];
            [self disableTabBarItems];
        }
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    BOOL leftIsGo = YES, rightIsGo = YES;
    NSString *segueCloseDesignerId = @"MTSegueCloseDesigner";
    if ([identifier isEqualToString:segueCloseDesignerId]) {
        leftIsGo = [self leftViewController] == nil ? YES :
                        [[self leftViewController] shouldPerformSegueWithIdentifier:identifier sender:sender];
        rightIsGo = [self rightViewController] == nil ? YES :
                        [[self rightViewController] shouldPerformSegueWithIdentifier:identifier sender:sender];
    }
    return leftIsGo && rightIsGo;
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if ([self leftView]) {
        NSMutableArray *subviews = [[NSMutableArray alloc] initWithArray:[[self leftView] subviews]];
        [subviews addObjectsFromArray:[[self rightView] subviews]];
        for (UIView *view in subviews) {
            if ([view isKindOfClass:[UIScrollView class]]) {
                CGFloat top = self.topLayoutGuide.length;
                CGFloat bot = self.bottomLayoutGuide.length;
                [(UIScrollView *)view setContentInset: UIEdgeInsetsMake(top, 0, bot, 0)];
                [(UIScrollView *)view setScrollIndicatorInsets: [(UIScrollView *)view contentInset]];
            }
        }
    }
}

- (id)leftViewController {
    return [self childViewControllers][0];
}

- (id)rightViewController {
    return [self childViewControllers][1];
}

- (IBAction)showReportDocumentList:(id)sender {
    [self.delegate viewControllerDidFinish:self animated:YES];
}

- (IBAction)showReportDesigner:(id)sender { }

- (IBAction)revealQuery:(id)sender { }

- (IBAction)done:(id)sender {
    NSError *error = nil;
    
    [self.document.managedObjectContext save:&error];
    if (error != nil) {
        [self.document.managedObjectContext save:&error];
    }
    [self.delegate viewControllerDidFinish:self animated:YES];
}
- (IBAction)redrawQueryVisualization:(id)sender {
    [[self queryBuilderControllerAdvanced] redraw];
}

- (IBAction)toggleEditModeQueryDesigner:(id)sender {
    
    if ([UIDevice isPad] == NO) {
        [[self queryBuilderController] edit:sender];
        BOOL isEditing = [self isEditing];
        [self setIsEditing: !isEditing];
        NSArray *items = [[[self navigationController] toolbar] items];
        NSMutableArray *tbItems = [items mutableCopy];
        NSUInteger buttonIndex = [tbItems indexOfObject:[self barButtonItemEdit]];
        if (buttonIndex != NSNotFound) {
            UIBarButtonSystemItem buttonType = isEditing ? UIBarButtonSystemItemEdit : UIBarButtonSystemItemDone;
            SEL toggleEditModeQueryDesigner = @selector(toggleEditModeQueryDesigner:);
            UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: buttonType
                                                                                           target: self
                                                                                           action: toggleEditModeQueryDesigner];
            
            
            tbItems[buttonIndex] = barButtonItem;
            [[[self navigationController] toolbar] setItems: tbItems animated:YES];
            [self setBarButtonItemEdit:barButtonItem];
        }
    } else {
        [[self queryBuilderController] edit:sender];
        BOOL isEditing = [self isEditing];
        [self setIsEditing: !isEditing];
        UIBarButtonSystemItem buttonType = isEditing ? UIBarButtonSystemItemEdit : UIBarButtonSystemItemDone;
        SEL toggleEditModeQueryDesigner = @selector(toggleEditModeQueryDesigner:);
        UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: buttonType
                                                                                       target: self
                                                                                       action: toggleEditModeQueryDesigner];
        
        [self.navigationItem setRightBarButtonItem:barButtonItem animated:YES];
        
        [self setBarButtonItemEdit:barButtonItem];
    }
}

- (MADQueryViewController *)queryBuilderController {
    return [self rightViewController];
}

- (MADQueryVisualizationViewController *)queryBuilderControllerAdvanced {
    return [self leftViewController];
}

- (void)viewControllerDidFinish:(id)controller {
    [self viewControllerDidFinish:controller animated:YES];
}

- (void)viewControllerDidFinish:(id)sender animated:(BOOL)animated {
    __weak MTQueryBuilderContainerController *weakSelf = self;
    BOOL procDelegateFunction = [sender isKindOfClass:[NSNumber class]] && [sender boolValue];
    [self dismissViewControllerAnimated:animated completion:^{
        if (procDelegateFunction) {
            [[weakSelf delegate] viewControllerDidFinish:weakSelf animated:YES];
        }
    }];
}

#pragma mark - MTTabBarImageProtocol

- (UIImage *)tabBarImage {
    return [UIDevice isModernOS] ?
            ([UIDevice isPad] ? [UIImage imageNamed:MADImageBarButtonItemDatabase8] :
                                [UIImage imageNamed:MADImageBarButtonItemDatabase8]) :
            [UIImage imageNamed:MADImageBarButtonItemDatabase];
}


#pragma mark - UIPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [self enableTabBarItems];
}

@end
