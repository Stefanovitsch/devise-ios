//
//  RegistrationViewController.m
//  Devise
//
//  Created by Patryk Kaczmarek on 19.11.2014.
//  Copyright (c) 2014 Netguru.co. All rights reserved.
//

#import "DVSDemoRegistrationViewController.h"
#import <Devise/Devise.h>

#import "DVSMacros.h"
#import "DVSDemoUser.h"
#import "DVSDemoUserDataSource.h"
#import "UIAlertView+DeviseDemo.h"

static NSString * const DVSEnterSegue = @"DisplayHomeView";
static NSString * const DVSTitleForUsername = @"Username";
static NSString * const DVSTitleForPassword = @"Password";
static NSString * const DVSTitleForEmail = @"E-mail";
static NSString * const DVSTitleForFirstName = @"First name";
static NSString * const DVSTitleForLastName = @"Last name";
static NSString * const DVSTitleForPhone = @"Phone";

@interface DVSDemoRegistrationViewController ()

@property (strong, nonatomic) DVSDemoUserDataSource *userDataSource;

@end

@implementation DVSDemoRegistrationViewController

#pragma mark - Object lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.userDataSource = [DVSDemoUserDataSource new];
    
    [self addFormWithTitleToDataSource:NSLocalizedString(DVSTitleForUsername, nil)];
    [self addFormWithTitleToDataSource:NSLocalizedString(DVSTitleForPassword, nil) secured:YES];
    [self addFormWithTitleToDataSource:NSLocalizedString(DVSTitleForEmail, nil)];
    [self addFormWithTitleToDataSource:NSLocalizedString(DVSTitleForFirstName, nil)];
    [self addFormWithTitleToDataSource:NSLocalizedString(DVSTitleForLastName, nil)];
    [self addFormWithTitleToDataSource:NSLocalizedString(DVSTitleForPhone, nil) keyboardType:UIKeyboardTypePhonePad];
}

#pragma mark - UIControl events

- (IBAction)signUpButtonTapped:(UIBarButtonItem *)sender {
    DVSDemoUser *newUser = [DVSDemoUser new];
    
    newUser.dataSource = self.userDataSource;
    
    newUser.username = [self valueForTitle:NSLocalizedString(DVSTitleForUsername, nil)];
    newUser.password = [self valueForTitle:NSLocalizedString(DVSTitleForPassword, nil)];
    newUser.email = [self valueForTitle:NSLocalizedString(DVSTitleForEmail, nil)];
    newUser.firstName = [self valueForTitle:NSLocalizedString(DVSTitleForFirstName, nil)];
    newUser.lastName = [self valueForTitle:NSLocalizedString(DVSTitleForLastName, nil)];
    newUser.phone = [self valueForTitle:NSLocalizedString(DVSTitleForPhone, nil)];
    
    [newUser registerWithSuccess:^{
        [self performSegueWithIdentifier:DVSEnterSegue sender:self];
    } failure:^(NSError *error) {
        UIAlertView *errorAlert = [UIAlertView dvs_alertViewForError:error
                                        statusDescriptionsDictionary:@{ @422: NSLocalizedString(@"E-mail is already taken.", nil) }];
        [errorAlert show];
    }];
}

@end
