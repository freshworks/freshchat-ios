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
#import "FDUtilities.h"
#import "FDIndexManager.h"
#import "FDResponseInfo.h"

@implementation HLFAQServices

-(NSURLSessionDataTask *)fetchAllCategories{
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    FDSecureStore *store = [FDSecureStore sharedInstance];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:HOTLINE_USER_DOMAIN,[store objectForKey:HOTLINE_DEFAULTS_DOMAIN]]]];
    request.HTTPMethod = HTTP_METHOD_GET;
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *appKey = [store objectForKey:HOTLINE_DEFAULTS_APP_KEY];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_CATEGORIES_PATH,appID];
    NSString *token = [NSString stringWithFormat:HOTLINE_REQUEST_PARAMS,appKey];
    [request setRelativePath:path andURLParams:@[token, @"deep=true", @"platform=ios"]];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
        [self importSolutions:[responseInfo responseAsDictionary]];
        [FDIndexManager setIndexingCompleted:NO];
        [FDIndexManager updateIndex];
        [[FDSecureStore sharedInstance] setObject:[NSDate date] forKey:HOTLINE_DEFAULTS_SOLUTIONS_LAST_UPDATED_TIME];
    }];
    return task;
}

-(void)importSolutions:(NSDictionary *)solutions{
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].backgroundContext;
    [context performBlock:^{
        NSArray *categories = solutions[@"categories"];
        
        for (int i=0; i<categories.count; i++) {
            NSLog(@"Category : %@, is enabled : %@", categories[i][@"title"], categories[i][@"enabled"]);
        }
        
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
                
                //Delete category with no articles
                if (category.articles.count == 0){
                    FDLog(@"Deleting category with title : %@ with ID : %@ because it doesn't have any articles !",category.title, category.categoryID);
                    [context deleteObject:category];
                }

            }else{
                
                if (category){
                    FDLog(@"Deleting category with title : %@ with ID : %@ because its disabled !",category.title, category.categoryID);
                    [context deleteObject:category];
                }
            }
        }
        [context save:nil];
        [self postNotification];
    }];
}

-(NSURLSessionDataTask *)vote:(BOOL)vote forArticleID:(NSNumber *)articleID inCategoryID:(NSNumber *)categoryID{
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    FDSecureStore *store = [FDSecureStore sharedInstance];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:HOTLINE_USER_DOMAIN,[store objectForKey:HOTLINE_DEFAULTS_DOMAIN]]]];

    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_ARTICLE_VOTE_PATH,appID,categoryID,articleID];
    request.HTTPMethod = HTTP_METHOD_PUT;
    NSString *appKey = [store objectForKey:HOTLINE_DEFAULTS_APP_KEY];
    NSString *token = [NSString stringWithFormat:HOTLINE_REQUEST_PARAMS,appKey];
    [request setRelativePath:path andURLParams:@[token, @"deep=true", @"platform=ios"]];
    NSDictionary *voteInfo;
    if (vote) {
        voteInfo = @{ @"article": @{ @"upvote" : @"1" } };
    }else{
        voteInfo = @{ @"article": @{ @"downvote" : @"1" } };
    }
    NSData *postData = [NSJSONSerialization dataWithJSONObject:voteInfo options:0 error:nil];
    request.HTTPBody = postData;
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FDResponseInfo *responseInfo,NSError *error) {
        if (!error) {
            FDLog(@"Article vote status: %@",[responseInfo responseAsDictionary]);
        }else{
            FDLog(@"Article voting failed :%@", error);
            FDLog(@"Response %@", responseInfo.response);
        }
    }];
    return task;
}

-(void)postNotification{
    [[NSNotificationCenter defaultCenter] postNotificationName:HOTLINE_SOLUTIONS_UPDATED object:self];
}

@end