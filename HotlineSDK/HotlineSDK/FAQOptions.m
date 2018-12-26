//
//  FAQOptions.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 14/06/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FreshchatSDK.h"

#import <Foundation/Foundation.h>
#import "FCUtilities.h"

@interface FAQOptions()

@property (nonatomic) int filterType;
@property (nonatomic, strong) NSArray *contactUsTags;
@property (nonatomic, strong) NSString *contactUsTitle;
@property (nonatomic, strong) NSArray *filterByTags;
@property (nonatomic, strong) NSString *tagViewTitle;

@end

@implementation FAQOptions

- (instancetype)init{
    self = [super init];
    if (self) {
        self.showFaqCategoriesAsGrid = YES;
        self.showContactUsOnFaqScreens = YES;
        self.showContactUsOnAppBar = NO;
        self.filterType = CATEGORY;
        self.filterByTags = @[];
    }
    return self;
}

-(void) filterByTags:(NSArray *) tags withTitle:(NSString *) title{
    [self filterByTags:tags withTitle:title andType:ARTICLE];
}

-(void) filterByTags:(NSArray *) tags withTitle:(NSString *) title  andType : (enum TagFilterType) type{
    
    self.filterByTags = [FCUtilities convertTagsArrayToLowerCase:tags];
    self.tagViewTitle = title;
    self.filterType = type;
}

-(NSString *) filteredViewTitle{
    return self.tagViewTitle;
}


-(void)filterContactUsByTags:(NSArray *) tags withTitle:(NSString *) title {
    self.contactUsTags = [FCUtilities convertTagsArrayToLowerCase:tags];
    self.contactUsTitle = title;
}

-(NSArray *) tags{
    return self.filterByTags;
}

-(enum TagFilterType) filteredType{
    return self.filterType;
}

-(NSArray *) contactUsFilterTags{
    return self.contactUsTags;
}

-(NSString *) contactUsFilterTitle{
    return self.contactUsTitle;
}

@end


@interface ConversationOptions()

@property (nonatomic, strong) NSArray *filterByTags;
@property (nonatomic, strong) NSString *tagViewTitle;
@property (nonatomic, strong) NSNumber *channelID;

@end

@implementation ConversationOptions

- (instancetype)init{
    self = [super init];
    if (self) {
        self.filterByTags = @[];
    }
    return self;
}

-(void) filterByTags:(NSArray *) tags withTitle:(NSString *) title{
    self.filterByTags = [FCUtilities convertTagsArrayToLowerCase:[tags mutableCopy]];
    self.tagViewTitle = title;
}

-(NSString *) filteredViewTitle{
    return self.tagViewTitle;
}

-(NSArray *) tags{
    return self.filterByTags;
}

-(void) filterByChannelID:(NSNumber *) channelID withTitle:(NSString *)title {
    self.channelID = channelID;
    self.tagViewTitle = title;
}

@end
