//
//  FAQOptions.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 14/06/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "Hotline.h"

#import <Foundation/Foundation.h>

@interface FAQOptions()

@property (nonatomic) NSArray *filterByTags;
@property (nonatomic) NSString *tagViewTitle;
@property (nonatomic) NSNumber *filterType;
@property (nonatomic) NSArray *contactUsTags;
@property (nonatomic) NSString *contactUsTitle;

@end

@implementation FAQOptions

- (instancetype)init{
    self = [super init];
    if (self) {
        self.showFaqCategoriesAsGrid = YES;
        self.showContactUsOnFaqScreens = YES;
        self.showContactUsOnAppBar = NO;
        self.filterByTags = @[];
    }
    return self;
}

-(void) filterByTags:(NSArray *) tags withTitle:(NSString *) title{
    [self filterByTags:tags withTitle:title andType:ARTICLE];
}

-(void) filterByTags:(NSArray *) tags withTitle:(NSString *) title  andType : (int) type{
    self.filterByTags = tags;
    self.tagViewTitle = title;
    self.filterType = [NSNumber numberWithInt:type];
}

-(NSString *) filteredViewTitle{
    return self.tagViewTitle;
}

-(void)filterContactUsByTags:(NSArray *) tags withTitle:(NSString *) title {
    self.contactUsTags = tags;
    self.contactUsTitle = title;
}

-(NSArray *) tags{
    return self.filterByTags;
}

-(NSNumber *) filteredType{
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

@property (nonatomic) NSArray *filterByTags;
@property (nonatomic) NSString *tagViewTitle;

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
    self.filterByTags = tags;
    self.tagViewTitle = title;
}

-(NSString *) filteredViewTitle{
    return self.tagViewTitle;
}

-(NSArray *) tags{
    return self.filterByTags;
}

@end
