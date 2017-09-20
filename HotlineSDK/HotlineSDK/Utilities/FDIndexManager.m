//
//  FDIndexManager.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 20/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDIndex.h"
#import "FDIndexManager.h"
#import "KonotorDataManager.h"
#import "HLArticle.h"
#import "FDArticleContent.h"
#import "FDSecureStore.h"
#import "HLMacros.h"
#import "FDUtilities.h"
#import "FDStringUtil.h"

#define ARTICLE_TITLE @"articleTitle"
#define ARTICLE_DESCRIPTION @"articleDescription"
#define HOTLINE_DEFAULTS_IS_INDEX_CREATED @"hotline_defaults_is_index_created"

static BOOL INDEX_INPROGRESS = NO;

@implementation FDIndexManager

#pragma Indexing

+(void)updateIndex{
    if(INDEX_INPROGRESS){
        FDLog(@"\n\n\n***********\n\n\n\nDouble indexing called\n\n\n***********\n\n\n")
        return;
    }
    BOOL indexState = [[FDSecureStore sharedInstance] boolValueForKey:HOTLINE_DEFAULTS_IS_INDEX_CREATED];
    if (!indexState) {
        [self createIndex];
    }
}

+(void)createIndex{
    INDEX_INPROGRESS = YES;
    [self setIndexingCompleted:NO];
    KonotorDataManager *datamanager = [KonotorDataManager sharedInstance];
    NSManagedObjectContext *context = datamanager.backgroundContext;
    [datamanager deleteAllIndices:^(NSError *error) {
        [context performBlock:^{
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_ARTICLE_ENTITY];
            NSError *error;
            NSArray *results = [context executeFetchRequest:request error:&error];
            if (!error) {
                if (results.count > 0) {
                    for (int i=0; i<[results count]; i++) {
                        HLArticle *article = results[i];
                        FDArticleContent *articleContent = [[FDArticleContent alloc]initWithArticle:article];
                        [self insertIndexforArticleWithContent:articleContent];
                    }
                    INDEX_INPROGRESS = NO;
                    [self setIndexingCompleted:YES];
                    [context save:nil];
                }
            }else{
                FDLog(@"Failed to create index. %@",error);
            }
        }];
    }];
}

+(void)setIndexingCompleted:(BOOL)state{
    [[FDSecureStore sharedInstance] setBoolValue:state forKey:HOTLINE_DEFAULTS_IS_INDEX_CREATED];
}

+(void)insertIndexforArticleWithContent:(FDArticleContent *)articleContent{
    articleContent.title = [FDStringUtil replaceSpecialCharacters:articleContent.title with:@" "];
    articleContent.articleDescription = [FDStringUtil replaceSpecialCharacters:articleContent.articleDescription with:@" "];
    [self stringByStrippingHTML:articleContent.articleDescription];
    NSMutableDictionary *indexInfo = [[NSMutableDictionary alloc] init];
    NSArray *substrings = [articleContent.title componentsSeparatedByString:@" "];
    indexInfo = [self convertIntoDictionary:indexInfo withArray:substrings forLabel:ARTICLE_TITLE and:articleContent.articleID];
    substrings = [articleContent.articleDescription componentsSeparatedByString:@" "];
    [self convertIntoDictionary:indexInfo withArray:substrings forLabel:ARTICLE_DESCRIPTION and:articleContent.articleID];
}

+(NSString *) stringByStrippingHTML:(NSString *)stringContent {
    NSRange r;
    while ((r = [stringContent rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        stringContent = [stringContent stringByReplacingCharactersInRange:r withString:@""];
    return stringContent;
}

+(NSMutableDictionary *)convertIntoDictionary:(NSMutableDictionary *)indexInfo withArray:(NSArray *)Array forLabel:(NSString *)label and:(NSNumber*)articleID{
    if (Array) {
        FDIndex *index = nil;
        for (int i=0; i < [Array count]; i++) {
            NSString* keyword = Array[i];
            if (keyword.length >= 3) {
                if ([indexInfo objectForKey:keyword]) {
                    index = indexInfo[keyword];
                }else{
                    index = [NSEntityDescription insertNewObjectForEntityForName:HOTLINE_INDEX_ENTITY inManagedObjectContext:[KonotorDataManager sharedInstance].backgroundContext];
                    index.keyWord = keyword;
                    index.articleID = articleID;
                }
                if ([label isEqualToString:ARTICLE_TITLE]) {
                    index.titleMatches = [NSNumber numberWithInt:[index.titleMatches intValue] + 1];
                }else{
                    index.descMatches  =  [NSNumber numberWithInt:[index.descMatches intValue] + 1];
                }
                indexInfo[index.keyWord] = index;
            }
        }
    }
    return indexInfo;
}

@end
