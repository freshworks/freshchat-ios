//
//  FDUserInfoField.m
//  FreshdeskSDK
//
//  Created by Arvchz on 27/05/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FDUserInfoForm.h"
#import "FDTextField.h"
#import "FDTheme.h"
#import "FDUtilities.h"
#import "FDProgressHUD.h"
#import "FDMacros.h"

@interface FDUserInfoForm ()

@property (nonatomic, strong) UIView *horizontalLine;
@property (nonatomic, strong) UIView *verticalLine;
@property (nonatomic, strong) FDTextField *nameField;
@property (nonatomic, strong) FDTextField *emailField;
@property (nonatomic, strong) FDTheme *theme;
@property (nonatomic) FEEDBACK_TYPE feedbackType;

@end

@implementation FDUserInfoForm

-(instancetype)init{
    self = [super init];
    if (self) {
        
        self.theme = [FDTheme sharedInstance];
        self.feedbackType = [FDUtilities getFeedBackType];
        [self initView];
    }
    return self;
}

-(instancetype) initWithName:(NSString * ) name withEmail: (NSString *) email andFeedBackType:(FEEDBACK_TYPE) feedbackType{
    self = [super init];
    if (self) {
        self.theme = [FDTheme sharedInstance];
        self.feedbackType = feedbackType;
        [self initView];
        [self setName:name andEmail:email];
    }
    return self;
}

-(void)setName:(NSString *) name andEmail:(NSString *) email {
    self.nameField.text = name;
    self.emailField.text = email;
}

-(NSString *)getUserName{
    return self.nameField.text;
}

-(NSString *)getEmailAddress{
    return self.emailField.text;
}

#pragma  mark - Views
-(void) initView{
    //Name Field
    self.nameField = [[FDTextField alloc] init];
    self.nameField.inputAccessoryView = nil;
    self.nameField.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameField.tintColor = [self.theme feedbackViewFontColor];
    self.nameField.textColor = [self.theme feedbackViewFontColor];
    self.nameField.backgroundColor = [self.theme feedbackViewUserFieldBackgroundColor];
    self.nameField.textAlignment = NSTextAlignmentCenter;
    self.nameField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;

    //Email Field
    self.emailField = [[FDTextField alloc] init];
    self.emailField.inputAccessoryView = nil;
    self.emailField.translatesAutoresizingMaskIntoConstraints = NO;
    self.emailField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailField.tintColor = [self.theme feedbackViewFontColor];
    self.emailField.textColor = [self.theme feedbackViewFontColor];
    self.emailField.backgroundColor = [self.theme feedbackViewUserFieldBackgroundColor];
    self.emailField.textAlignment = NSTextAlignmentCenter;
    self.emailField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;

    //Horizontal and vertical lines
    self.horizontalLine = [[UIView alloc] init];
    self.horizontalLine.translatesAutoresizingMaskIntoConstraints = NO;
    self.horizontalLine.backgroundColor = [self.theme feedbackViewUserFieldPlaceholderColor];

    self.verticalLine = [[UIView alloc] init];
    self.verticalLine.translatesAutoresizingMaskIntoConstraints = NO;
    self.verticalLine.backgroundColor = [self.theme feedbackViewUserFieldPlaceholderColor];

    [self addSubview:self.nameField];
    [self addSubview:self.emailField];
    [self addSubview:self.horizontalLine];
    [self addSubview:self.verticalLine];

    NSDictionary *views = @{@"nameField" : self.nameField, @"verticalLine" : self.verticalLine, @"emailField" : self.emailField, @"horizontalLine" : self.horizontalLine};;
    NSDictionary *metrics =  @{ @"textfieldHeight" : @(35) };

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[horizontalLine]|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[verticalLine(textfieldHeight)]" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[horizontalLine(1)][nameField(textfieldHeight)]" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[emailField(textfieldHeight)]" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[nameField(emailField)][verticalLine(0.5)][emailField]|" options:NSLayoutFormatAlignAllTop metrics:metrics views:views]];
    
    [self setTextfieldPlaceholders];

}

-(void)setTextfieldPlaceholders{
    switch (self.feedbackType) {
        case FEEDBACK_TYPE_NAME_AND_EMAIL_REQUIRED:
            self.nameField.attributedPlaceholder = [self attributedStringForPlaceholder:FDLocalizedString(@"Name Placeholder Required Text" )];
            self.emailField.attributedPlaceholder = [self attributedStringForPlaceholder:FDLocalizedString(@"Email Placeholder Required Text" )];
            break;
            
        case FEEDBACK_TYPE_NAME_REQUIRED_AND_EMAIL_OPTIONAL:
            self.nameField.attributedPlaceholder = [self attributedStringForPlaceholder:FDLocalizedString(@"Name Placeholder Required Text" )];
            self.emailField.attributedPlaceholder = [self attributedStringForPlaceholder:FDLocalizedString(@"Email Placeholder Optional Text" )];
            break;

        case FEEDBACK_TYPE_ANONYMOUS:
            break;

        default:
            break;
    }
}

-(NSAttributedString *)attributedStringForPlaceholder:(NSString *)string{
    UIColor *textPlaceHolderColor = [self.theme feedbackViewUserFieldPlaceholderColor];
    return [[NSAttributedString alloc] initWithString:string attributes:@{ NSForegroundColorAttributeName: textPlaceHolderColor}];
}

#pragma mark - Validations
-(BOOL)isValid {
    switch (self.feedbackType) {
        case FEEDBACK_TYPE_NAME_AND_EMAIL_REQUIRED:
            return [self nameAndEmailRequiredValidation];
            break;

        case FEEDBACK_TYPE_NAME_REQUIRED_AND_EMAIL_OPTIONAL:
            return [self nameAndEmailOptionalValidation];
            break;

        case FEEDBACK_TYPE_ANONYMOUS:
            return YES;
            break;

        default:
            return NO;
            break;
    }
}

-(BOOL)isValidWithNameRequired:(BOOL)nameRequired andEmailRequired:(BOOL) emailRequired {
    
    if (nameRequired && ![self isNameValid]) {
        [FDProgressHUD showErrorWithStatus:FDLocalizedString(@"Name Required Alert Message Text" )];
        return NO;
    }
    
    if (emailRequired && self.emailField.text.length == 0 ) {
        [FDProgressHUD showErrorWithStatus:FDLocalizedString(@"Email Required Alert Message Text" )];
        return NO;
    }
    
    if (emailRequired && ![self isEmailValid]) {
        [FDProgressHUD showErrorWithStatus:FDLocalizedString(@"Invalid Email Alert Message Text")];
        return NO;
    }
    
    return YES;
}

-(BOOL)nameAndEmailRequiredValidation{
    return [self isValidWithNameRequired:YES andEmailRequired:YES];
}

-(BOOL)nameAndEmailOptionalValidation{
    return [self isValidWithNameRequired:YES andEmailRequired:NO];
}

-(BOOL)isNameValid{
    return  ([trimString(self.nameField.text) length] > 1);
}

-(BOOL)isEmailValid{
    return [FDUtilities isValidEmail:self.emailField.text];
}

@end