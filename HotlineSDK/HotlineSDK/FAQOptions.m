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
@property (nonatomic) NSString *filteredViewTitle;

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
    self.filterByTags = tags;
    self.filteredViewTitle = title;
}

-(NSString *) filteredViewTitle{
    return self.filteredViewTitle;
}

-(NSArray *) tags{
    return self.filterByTags;
}

@end
