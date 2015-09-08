//
//  FDRanking.h
//  FreshdeskSDK
//
//  Created by kirthikas on 05/02/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MobiHelpDatabase.h"

#define ARTICLE_TITLE @"articleTitle"
#define ARTICLE_DESCRIPTION @"articleDescription"

@interface FDRanking : NSObject

+(NSMutableArray *)rankTheArticleForSearchTerm:(NSString *)term withContext:(NSManagedObjectContext *)context;

@end
