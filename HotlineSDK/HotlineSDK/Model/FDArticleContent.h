//
//  FDArticleContent.h
//  FreshdeskSDK
//
//  Created by kirthikas on 11/06/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLArticle.h"

@interface FDArticleContent : NSObject

@property (nonatomic, retain) NSNumber * articleID;
@property (nonatomic, retain) NSString * articleDescription;
@property (nonatomic, retain) NSString * title;

-(id)initWithArticle:(HLArticle *)article;

@end
