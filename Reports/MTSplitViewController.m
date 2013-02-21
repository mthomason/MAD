//
//  ViewController.m
//  MTSplitViewController
//
//  Created by Michael Thomason on 2/13/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTSplitViewController.h"

@interface MTSplitViewController ()

@property (retain, nonatomic) IBOutlet UIView *leftView;
@property (retain, nonatomic) IBOutlet UIView *rightView;
@property (retain, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *bogusConstraints;
@property (retain, nonatomic) IBOutlet UIToolbar *toolbarTop;

@end

@implementation MTSplitViewController

- (void)dealloc {
    [_documentToOpen release];
    [_leftView release];
    [_rightView release];
    [_bogusConstraints release];
    [_toolbarTop release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"%@ %@", [[self childViewControllers] objectAtIndex:0], [[self childViewControllers] objectAtIndex:1]);

    [[self delegateContentController] displayContentController:
     [[self childViewControllers] objectAtIndex:0]];
    
    [[self delegateContentController] displayContentController:
     [[self childViewControllers] objectAtIndex:1]];
    
}

- (id)leftViewController {
    return [[[[self childViewControllers] objectAtIndex:0] retain] autorelease];
}

- (id)rightViewController {
    return [[[[self childViewControllers] objectAtIndex:1] retain] autorelease];
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UIView *leftView = [[self leftView] retain];
    UIView *rightView = [[self rightView] retain];

    [[self view] removeConstraints:[self bogusConstraints]];

    NSString *constraintAsciiArtHorizontal = @"H:|-(==0.0000)-[leftView(==320.0000)]-(==0.0000)-[rightView]-(==0.0000)-|";

    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(leftView, rightView);
    
    
    NSArray *constraintsHorizontal = [NSLayoutConstraint constraintsWithVisualFormat:constraintAsciiArtHorizontal
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:viewsDictionary];
    [[self view] addConstraints:constraintsHorizontal];
    
    [leftView release];
    [rightView release];
}

- (IBAction)showReportDocumentList:(id)sender {
    [[self delegate] viewControllerDidFinish:self];
}

- (IBAction)showReportDesigner:(id)sender {
    MTViewControllerQueryBuilder *queryBuilderController = [[self queryBuilderController] retain];

    [queryBuilderController release];
}

- (IBAction)toggleEditModeQueryDesigner:(id)sender {
    MTViewControllerQueryBuilder *queryBuilderController = [[self queryBuilderController] retain];
    BOOL isEditing = ![[queryBuilderController tableViewQueryBuilder] isEditing];

    UIBarButtonSystemItem buttonType = isEditing ? UIBarButtonSystemItemDone: UIBarButtonSystemItemEdit;
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: buttonType
                                                                                   target: self
                                                                                   action: @selector(toggleEditModeQueryDesigner:)];
    NSMutableArray *tbItems = [[NSMutableArray alloc] initWithArray:[[self toolbarTop] items]];
    [tbItems replaceObjectAtIndex:([tbItems count] - 1) withObject: barButtonItem];
    [[self toolbarTop] setItems: tbItems];
    [tbItems release];

    
    [[queryBuilderController tableViewQueryBuilder] setEditing:isEditing];
    [queryBuilderController release];
}

- (MTViewControllerQueryBuilder *)queryBuilderController {
    return [[[self rightViewController] retain] autorelease];
}

- (MTQueryBuilderAdvancedSchemaViewController *)queryBuilderControllerAdvanced {
    return [[[self leftViewController] retain] autorelease];
}

@end
