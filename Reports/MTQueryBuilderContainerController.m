//
//  MTQueryBuilderContainerController.m
//  MTQueryBuilderContainerController
//
//  Created by Michael Thomason on 2/13/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryBuilderContainerController.h"
#import <CoreData/CoreData.h>
#import "MTStoreKitController+NonRenewableLicensing.h"
#import "MTReportDesignerViewController.h"
#import "MTApplicationInstance.h"
#import "UIDevice+Hack.h"

@interface MTQueryBuilderContainerController ()

@property (nonatomic, retain) IBOutlet UIView *leftView;
@property (nonatomic, retain) IBOutlet UIView *rightView;
@property (nonatomic, retain) IBOutletCollection(NSLayoutConstraint) NSArray *bogusConstraints;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemEdit;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemRevealQuery;

@property (nonatomic, retain) NSArray *constraintsViewWillAppear;

@property (nonatomic, retain) UIPopoverController *popover;

@property (nonatomic, assign) BOOL isEditing;

@end

@implementation MTQueryBuilderContainerController

- (void)dealloc {
    [_constraintsViewWillAppear release];
    [_leftView release];
    [_rightView release];
    [_bogusConstraints release];
    [_barButtonItemEdit release];
    [_barButtonItemRevealQuery release];
    [_popover release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        UILabel *labelMadDesigner = [[UILabel alloc] initWithFrame:CGRectZero];
        [labelMadDesigner setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        NSAttributedString *attributedString = [[MTApplicationInstance localizedAttributedApplicationNameMadQuery] retain];
        [labelMadDesigner setAttributedText:attributedString];
        [[self navigationItem] setTitleView:labelMadDesigner];
        [[[self navigationItem] titleView] sizeToFit];
        [attributedString release];
        [labelMadDesigner release];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setIsEditing:NO];

    NSArray *childViewControllers = [self childViewControllers];
    [[self delegateContentController] displayContentController: [childViewControllers objectAtIndex:0]];
    [[self delegateContentController] displayContentController: [childViewControllers objectAtIndex:1]];
    
    [[self view] removeConstraints:[self bogusConstraints]];
    
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
    [[[self navigationItem] titleView] sizeToFit];
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
            [mutableItems release];
        }
    }];
    
    [[self view] addConstraints:[self constraintsViewWillAppear]];
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[self view] removeConstraints:[self constraintsViewWillAppear]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([self popover] != nil) {
        if ([[self popover] isPopoverVisible]) {
            [[self popover] dismissPopoverAnimated:YES];
        }
    }
    Class popoverSegueClass = [UIStoryboardPopoverSegue class];
    if ([segue isKindOfClass:popoverSegueClass]) {
        [self setPopover:[(UIStoryboardPopoverSegue *)segue popoverController]];
    }
    if ([[segue identifier] isEqualToString:@"MTSegueIdentifierShowReportDesigerFromSplitView"]) {
        if ([[segue destinationViewController] isKindOfClass: [MTReportDesignerViewController class]]) {
            [[segue destinationViewController] setDelegate: self];
        } else if ([[segue destinationViewController] isKindOfClass:[UINavigationController class]]) {
            [(MTReportDesignerViewController *)[[segue destinationViewController] topViewController] setDelegate:self];
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
        [subviews release];
    }
}

- (id)leftViewController {
    return [[[[self childViewControllers] objectAtIndex:0] retain] autorelease];
}

- (id)rightViewController {
    return [[[[self childViewControllers] objectAtIndex:1] retain] autorelease];
}

- (IBAction)showReportDocumentList:(id)sender {
    [[self delegate] viewControllerDidFinish:self animated:YES];
}

- (IBAction)showReportDesigner:(id)sender { }

- (IBAction)revealQuery:(id)sender { }

- (IBAction)done:(id)sender {
    NSError *error = nil;
    
    MAReportDocument *reportDocument = [[AppDelegate app] activeDocument];
    [[reportDocument managedObjectContext] save:&error];
    if (error != nil) {
        [[reportDocument managedObjectContext] save:&error];
    }
    [[self delegate] viewControllerDidFinish:self animated:YES];
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
            
            
            [tbItems replaceObjectAtIndex:buttonIndex withObject: barButtonItem];
            [[[self navigationController] toolbar] setItems: tbItems animated:YES];
            [self setBarButtonItemEdit:barButtonItem];
            [barButtonItem release];
        }
        [tbItems release];
    } else {
        [[self queryBuilderController] edit:sender];
        BOOL isEditing = [self isEditing];
        [self setIsEditing: !isEditing];
        UIBarButtonSystemItem buttonType = isEditing ? UIBarButtonSystemItemEdit : UIBarButtonSystemItemDone;
        SEL toggleEditModeQueryDesigner = @selector(toggleEditModeQueryDesigner:);
        UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: buttonType
                                                                                       target: self
                                                                                       action: toggleEditModeQueryDesigner];
        
        [[self navigationItem] setRightBarButtonItem:barButtonItem animated:YES];
        
        [self setBarButtonItemEdit:barButtonItem];
        [barButtonItem release];
    }

}

- (MTQueryBuilderViewController *)queryBuilderController {
    return [[[self rightViewController] retain] autorelease];
}

- (MTQueryBuilderAdvancedViewController *)queryBuilderControllerAdvanced {
    return [[[self leftViewController] retain] autorelease];
}

- (void)viewControllerDidFinish:(id)controller {
    [self viewControllerDidFinish:controller animated:YES];
}

- (void)viewControllerDidFinish:(id)sender animated:(BOOL)animated {
    [self dismissViewControllerAnimated:animated completion:^{
        if ([sender isKindOfClass:[NSNumber class]]) {
            if ([sender boolValue]) {
                [[self delegate] viewControllerDidFinish:self animated:YES];
            }
        }
    }];
}

@end
