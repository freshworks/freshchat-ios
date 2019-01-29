//
//  FCUnknownFragment.m
//  FreshchatSDK
//
//  Created by Harish Kumar on 05/09/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import "FCUnsupportedFragment.h"
#import "FCAutolayoutHelper.h"
#import "FCRemoteConfig.h"

#define CONTENT_PADDING 8
#define MAXIMUM_LINES 2 //Max lines allowed for unsupported fragment message

@implementation FCUnsupportedFragment

-(id) initWithFragment: (FragmentData *) fragment {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.fragmentData = fragment;
        FCTheme *theme = [FCTheme sharedInstance];
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [theme unsupportedMsgFragmentBackgroundColor];
        self.layer.borderColor=[[theme unsupportedMsgFragmentBorderColor] CGColor];
        self.layer.borderWidth=0.5;
        self.layer.cornerRadius=5.0;
        
        UIImageView *unknownFileIcon = [[UIImageView alloc] init];
        unknownFileIcon.translatesAutoresizingMaskIntoConstraints = NO;
        unknownFileIcon.image = [[FCTheme sharedInstance]
                                 getImageValueWithKey:IMAGE_UNKNOWN_MSG_TYPE_ICON];
        [self addSubview:unknownFileIcon];
        
        UILabel *errorMsgLbl = [[UILabel alloc]init];
        errorMsgLbl.translatesAutoresizingMaskIntoConstraints = NO;
        [errorMsgLbl setBackgroundColor:[UIColor clearColor]];
        [errorMsgLbl setFont:[theme unsupportedMsgFragmentFont]];
        [errorMsgLbl setTextColor:[theme unsupportedMsgFragmentFontColor]];
        [self addSubview:errorMsgLbl];
        errorMsgLbl.numberOfLines = 2;
        errorMsgLbl.text = [self getUnsupportedFragmentMsg:fragment];
        
        CGSize maximumLabelSize = CGSizeMake(236, FLT_MAX);
        
        CGSize expectedLabelSize = [errorMsgLbl.text sizeWithFont:[theme unsupportedMsgFragmentFont] constrainedToSize:maximumLabelSize lineBreakMode:errorMsgLbl.lineBreakMode];
        
        float maxAllowedHeight = MIN((errorMsgLbl.intrinsicContentSize.height * MAXIMUM_LINES), expectedLabelSize.height);
        NSDictionary *paddingMetrics = @{@"padding":@8, @"iconWidth" : @12, @"iconHeight": @15, @"ErrorMsgHeight" : @(maxAllowedHeight)};
        NSDictionary *views = @{@"errorMessage" : errorMsgLbl, @"image": unknownFileIcon};
        
        [FCAutolayoutHelper centerY:unknownFileIcon onView:self];
        [FCAutolayoutHelper centerY:errorMsgLbl onView:self];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-padding-[image(iconWidth)]-padding-[errorMessage]-padding-|" options:0 metrics:paddingMetrics views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-padding-[errorMessage(ErrorMsgHeight)]-padding-|" options:0 metrics:paddingMetrics views:views]];
        self.userInteractionEnabled = false;
    }
    return self;
}

- (NSString *) getUnsupportedFragmentMsg : (FragmentData *) fragment {
    
    NSDictionary *unsupprtedMsgDict = @{};
    BOOL canDisplayErrorCodes = [FCRemoteConfig sharedInstance].unsupportedFragErrMsg.displayErrorCodes;
    NSString *errorCodePlaceholder = [FCRemoteConfig sharedInstance].unsupportedFragErrMsg.errorCodePlaceholder;
    NSDictionary *globalErrorMessages = [FCRemoteConfig sharedInstance].unsupportedFragErrMsg.globalErrorMessage;
    NSArray *errorMessageByTypes = [FCRemoteConfig sharedInstance].unsupportedFragErrMsg.errorMessageByTypes;
    if([errorMessageByTypes count] != 0){
        for(NSDictionary * errorMsgDict in errorMessageByTypes){
            if([errorMsgDict[@"fragmentType"] intValue] == [fragment.type intValue]){
                for(NSDictionary *errorMsg in errorMsgDict[@"errorMessages"]){
                    if([fragment.contentType isEqualToString:errorMsg[@"contentType"]]){
                        unsupprtedMsgDict = errorMsg;
                        break;
                    }
                }
                if(unsupprtedMsgDict.count == 0){
                    unsupprtedMsgDict = errorMsgDict[@"defaultErrorMessage"];
                    break;
                }
            }
        }
    }
    if(unsupprtedMsgDict.count == 0 && ([globalErrorMessages count] != 0)){
        unsupprtedMsgDict = globalErrorMessages;
    }
    if([unsupprtedMsgDict count] != 0){
        return ((canDisplayErrorCodes) ? [NSString stringWithFormat:@"%@  %@", [unsupprtedMsgDict valueForKey:@"errorMessage"], [NSString stringWithFormat:errorCodePlaceholder,[[unsupprtedMsgDict valueForKey:@"errorCode"] intValue]]] : [unsupprtedMsgDict valueForKey:@"errorMessage"]);
    }
    return @"Unsupported Content";// Second fallback no need to localize cc: @prasannanfd
}

@end
