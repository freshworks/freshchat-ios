//
//  HLFAQServices.m
//  
//
//  Created by Aravinth Chandran on 21/09/15.
//
//

#import "HLFAQServices.h"
#import "HLAPIClient.h"
#import "HLAPI.h"
#import "KonotorDataManager.h"
#import "HLArticle.h"
#import "HLCategory.h"
#import "FDLocalNotification.h"
#import "FDSecureStore.h"
#import "HLServiceRequest.h"
#import "HLMacros.h"
#import "FDIndex.h"
#import "FDUtilities.h"


#define MOBIHELP_DEFAULTS_IS_INDEX_CREATED @"mobihelp_defaults_is_index_created"    

@implementation HLFAQServices

static bool INDEX_INPROGRESS=NO;

-(NSURLSessionDataTask *)fetchCategoriesInBatches{
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:[NSURL URLWithString:HOTLINE_USER_DOMAIN]];
    request.HTTPMethod = HTTP_METHOD_GET;
    [request setRelativePath:HOTLINE_API_CATEGORIES andURLParams:HOTLINE_REQUEST_PARAMS];
    
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(id responseObject, NSError *error) {
        __block BOOL canAbortRequest = NO;
        __block NSMutableArray *solutions = [NSMutableArray new];
        dispatch_group_t group = dispatch_group_create();
        NSArray *categories = responseObject[@"categories"];

        for (int i=0; i<categories.count; i++) {
            
            if (canAbortRequest) {
                break;
            }
            
            dispatch_group_enter(group);
            
            if (NO) { // If fetch not required for a particular category
                dispatch_group_leave(group);
                continue;
            }
            
            
            NSDictionary *categoryInfo = categories[i];
            NSString *categoryID = categoryInfo[@"categoryId"];
            [request setRelativePath:[NSString stringWithFormat:HOTLINE_API_ARTICLES,categoryID] andURLParams:HOTLINE_REQUEST_PARAMS];
            [apiClient request:request withHandler:^(id responseObject, NSError *error) {
                if (!error) {
                    [solutions addObject:@{ @"category" : categoryInfo, @"articles" : responseObject[@"articles"]}];
                }else{
                    canAbortRequest = YES;
                }
                dispatch_group_leave(group);
            }];
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            if (!canAbortRequest) {
                [[KonotorDataManager sharedInstance]deleteAllSolutions:^(NSError *error) {
                    if (!error) {
                        [[FDSecureStore sharedInstance] setObject:[NSDate date] forKey:HOTLINE_DEFAULTS_SOLUTIONS_LAST_UPDATED_TIME];
                    }
                }];
            }
        });
    }];
    return task;
}

-(NSURLSessionDataTask *)fetchAllCategories{
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:[NSURL URLWithString:HOTLINE_USER_DOMAIN]];
    request.HTTPMethod = HTTP_METHOD_GET;
    NSString *URLParams = [NSString stringWithFormat:@"%@&%@",HOTLINE_REQUEST_PARAMS,@"deep=true"];
    [request setRelativePath:HOTLINE_API_CATEGORIES andURLParams:URLParams];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(id responseObject, NSError *error) {
        [self importSolutions:responseObject];
        [[FDSecureStore sharedInstance] setObject:[NSDate date] forKey:HOTLINE_DEFAULTS_SOLUTIONS_LAST_UPDATED_TIME];
    }];
    return task;
}

-(void)importSolutions:(NSDictionary *)solutions{
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].backgroundContext;
    [context performBlock:^{
        NSArray *categories = solutions[@"categories"];
        for(int i=0; i<categories.count; i++){
            NSDictionary *categoryInfo = categories[i];
            HLCategory *category = [HLCategory getWithID:categoryInfo[@"categoryId"] inContext:context];
            BOOL isCategoryEnabled = [categoryInfo[@"enabled"]boolValue];
            if (isCategoryEnabled) {
                if (category) {
                    NSDate *updateTime = [NSDate dateWithTimeIntervalSince1970:[categoryInfo[@"lastUpdatedAt"]doubleValue]];
                    if ([category.lastUpdatedTime compare:updateTime] == NSOrderedAscending) {
                        [category updateWithInfo:categoryInfo];
                        FDLog(@"Category with ID:%@ updated", categoryInfo[@"categoryId"]);
                    }
                }else{
                    category = [HLCategory createWithInfo:categoryInfo inContext:context];
                }
            }else{
                if (category) [context deleteObject:category];
            }
        }
        [context save:nil];
        [self updateIndex];
        [self postNotification];
    }];
}

-(NSURLSessionDataTask *)vote:(BOOL)vote forArticleID:(NSNumber *)articleID inCategoryID:(NSNumber *)categoryID{
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    NSString *URLString = [NSString stringWithFormat:HOTLINE_API_ARTICLE_VOTE,categoryID,articleID];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:[NSURL URLWithString:HOTLINE_USER_DOMAIN]];
    request.HTTPMethod = HTTP_METHOD_PUT;
    NSString *URLParams = [NSString stringWithFormat:@"%@&%@",HOTLINE_REQUEST_PARAMS,@"platform=ios"];
    [request setRelativePath:URLString andURLParams:URLParams];
    NSDictionary *voteInfo;
    if (vote) {
        voteInfo = @{ @"article": @{ @"upvote" : @"1", @"downvote" : @"-1" } };
    }else{
        voteInfo = @{ @"article": @{ @"upvote" : @"-1", @"downvote" : @"1" } };
    }
    NSData *postData = [NSJSONSerialization dataWithJSONObject:voteInfo options:0 error:nil];
    request.HTTPBody = postData;
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(id responseObject, NSError *error) {
        FDLog(@"Article vote status: %@",responseObject);
    }];
    return task;
}

-(void)postNotification{
    [[NSNotificationCenter defaultCenter] postNotificationName:HOTLINE_SOLUTIONS_UPDATED object:self];
}

#pragma Indexing

-(void)updateIndex{
    if(INDEX_INPROGRESS){
        return;
    }
    BOOL indexState = [self.secureStore boolValueForKey:MOBIHELP_DEFAULTS_IS_INDEX_CREATED];
    if (!indexState) {
        [self createIndex];
    }
}

-(void)createIndex{
    INDEX_INPROGRESS = YES;
    [self setIndexingCompleted:NO];
    KonotorDataManager *datamanager = [KonotorDataManager sharedInstance];
    [datamanager deleteAllIndices:^(NSError *error) {
        [datamanager.backgroundContext performBlock:^{
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_ARTICLE_ENTITY];
            NSError *error;
            NSArray *results = [datamanager.backgroundContext executeFetchRequest:request error:&error];
            if (!error) {
                if (results.count > 0) {
                    for (int i=0; i<[results count]; i++) {
                        HLArticle *article = results[i];
                        FDArticleContent *articleContent = [[FDArticleContent alloc]initWithArticle:article];
                        [self insertIndexforArticleWithContent:articleContent];
                    }
                    INDEX_INPROGRESS = NO;
                    [self setIndexingCompleted:YES];
                    [datamanager save];
                }
            }else{
                FDLog(@"Failed to create index. %@",error);
            }
        }];
    }];
}

-(void)setIndexingCompleted:(BOOL)state{
    [self.secureStore setBoolValue:state forKey:MOBIHELP_DEFAULTS_IS_INDEX_CREATED];
}

-(void)insertIndexforArticleWithContent:(FDArticleContent *)articleContent{
    articleContent.title = [FDUtilities replaceSpecialCharacters:articleContent.title with:@" "];
    articleContent.articleDescription = [FDUtilities replaceSpecialCharacters:articleContent.articleDescription with:@" "];
    [self stringByStrippingHTML:articleContent.articleDescription];
    NSMutableDictionary *indexInfo = [[NSMutableDictionary alloc] init];
    NSArray *substrings = [articleContent.title componentsSeparatedByString:@" "];
    indexInfo = [self convertIntoDictionary:indexInfo withArray:substrings forLabel:ARTICLE_TITLE and:articleContent.articleID];
    substrings = [articleContent.articleDescription componentsSeparatedByString:@" "];
    indexInfo = [self convertIntoDictionary:indexInfo withArray:substrings forLabel:ARTICLE_DESCRIPTION and:articleContent.articleID];
}

-(NSString *) stringByStrippingHTML:(NSString *)stringContent {
    NSRange r;
    while ((r = [stringContent rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        stringContent = [stringContent stringByReplacingCharactersInRange:r withString:@""];
    return stringContent;
}

-(NSMutableDictionary *)convertIntoDictionary:(NSMutableDictionary *)indexInfo withArray:(NSArray *)Array forLabel:(NSString *)label and:(NSNumber*)articleID{
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

-(NSArray *)fetchAllIndices{
    __block NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    __block NSArray *fetchedTuples = [[NSArray alloc] init];
    __block NSManagedObjectContext *context = [KonotorDataManager sharedInstance].backgroundContext;
    [context performBlockAndWait:^{
        NSEntityDescription *entity = [NSEntityDescription entityForName:HOTLINE_INDEX_ENTITY inManagedObjectContext:context];
        NSError *error;
        [fetchRequest setEntity:entity];
        fetchedTuples= [context executeFetchRequest:fetchRequest error:&error];
        if (error) {
            FDLog(@"Fetch all entries failed : %@", error);
        }
    }];
    return fetchedTuples ? [NSMutableArray arrayWithArray:fetchedTuples] : nil;
}


@end