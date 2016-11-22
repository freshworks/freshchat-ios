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
#import "FDDateUtil.h"
#import "HLArticleTagManager.h"
#import "FDTags.h"

@implementation HLFAQServices

-(NSURLSessionDataTask *)fetchAllCategories:(void (^)(NSError *))completion{
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    FDSecureStore *store = [FDSecureStore sharedInstance];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithMethod:HTTP_METHOD_GET];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *appKey = [store objectForKey:HOTLINE_DEFAULTS_APP_KEY];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_CATEGORIES_PATH,appID];
    NSString *token = [NSString stringWithFormat:HOTLINE_REQUEST_PARAMS,appKey];
    NSNumber *lastUpdateTime = [FDUtilities getLastUpdatedTimeForKey:HOTLINE_DEFAULTS_SOLUTIONS_LAST_UPDATED_SERVER_TIME];
    lastUpdateTime = @([lastUpdateTime longLongValue] + 1 ); // hack for not getting back same response from server - Rex
    NSString *afterTime = [NSString stringWithFormat:@"after=%@",lastUpdateTime];
    [request setRelativePath:path andURLParams:@[token, @"deep=true", afterTime]];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
        if(!error){
            [self importSolutions:[responseInfo responseAsDictionary]withCompletion:^(NSError *error) {
                if(!error){
                    if(responseInfo){
                        NSArray *categories = [responseInfo responseAsDictionary][@"categories"];
                        if(categories && categories.count > 0 ){
                            // Indexing is costly, don't do it unless there is a need for it.
                            [FDIndexManager setIndexingCompleted:NO];
                            [FDIndexManager updateIndex];
                        }
                    }
                }
                if(completion){
                    completion(error);
                }
            }];
        }
        else {
            if(completion){
                completion(error);
            }
        }
    }];
    return task;
}

-(void)importSolutions:(NSDictionary *)solutions withCompletion:(void (^)(NSError *))completion{
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].backgroundContext;
    [context performBlock:^{
        NSNumber *lastUpdated = [FDUtilities getLastUpdatedTimeForKey:HOTLINE_DEFAULTS_SOLUTIONS_LAST_UPDATED_SERVER_TIME];
        NSArray *categories = solutions[@"categories"];
        for(int i=0; i<categories.count; i++){
            NSDictionary *categoryInfo = categories[i];
            lastUpdated = [FDDateUtil maxDateOfNumber:lastUpdated andStr:categoryInfo[@"lastUpdatedAt"]];
            HLCategory *category = [HLCategory getWithID:categoryInfo[@"categoryId"] inContext:context];
            BOOL isCategoryEnabled = [categoryInfo[@"enabled"]boolValue];
            BOOL isIOSPlatformAvail = [categoryInfo[@"platforms"] containsObject:@"ios"];
            NSArray *tags = categoryInfo[@"tags"];
            if (isCategoryEnabled && isIOSPlatformAvail) {
                if (category) {
                    FDLog(@"Updating category:%@ [%@abled]", categoryInfo[@"title"], ( isCategoryEnabled ? @"en" : @"dis"));
                    [category updateWithInfo:categoryInfo];
                }else{
                    FDLog(@"New category:%@ [%@abled]", categoryInfo[@"title"], ( isCategoryEnabled ? @"en" : @"dis"));
                    category = [HLCategory createWithInfo:categoryInfo inContext:context];
                }
                if(tags){
                    for(NSString *tagName in tags){
                        [FDTags createTagWithInfo:[FDTags createDictWithTagName:tagName type:[NSNumber numberWithInt: FDTagTypeCategory] andIdvalue:categoryInfo[@"categoryId"]] inContext:context];
                    }
                }
                
                //Delete category with no articles
                if (category.articles.count == 0){
                    FDLog(@"Deleting category with title : %@ with ID : %@ because it doesn't contain any articles !",category.title, category.categoryID);
                    [context deleteObject:category];
                }

            }else{
                if (category){
                    FDLog(@"Deleting category with title : %@ with ID : %@ because its disabled !",category.title, category.categoryID);
                    for(HLArticle *article in category.articles){
                        [[HLArticleTagManager sharedInstance] removeTagsForArticleId:article.articleID];
            
                        [FDTags removeTagsForTaggableId:article.articleID andType:[NSNumber numberWithInt: FDTagTypeArticle] inContext:context];
                    }
                    [[HLArticleTagManager sharedInstance]save];
                    [context deleteObject:category];
                }
            }
        }
        NSError *err;
        [context save:&err];
        [FDLocalNotification post:HOTLINE_SOLUTIONS_UPDATED];
        [[FDSecureStore sharedInstance] setObject:lastUpdated forKey:HOTLINE_DEFAULTS_SOLUTIONS_LAST_UPDATED_SERVER_TIME];
        if(completion){
            completion(err);
        }
    }];
}

-(NSURLSessionDataTask *)vote:(BOOL)vote forArticleID:(NSNumber *)articleID inCategoryID:(NSNumber *)categoryID{
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    FDSecureStore *store = [FDSecureStore sharedInstance];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithMethod:HTTP_METHOD_PUT];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_ARTICLE_VOTE_PATH,appID,categoryID,articleID];
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
    [request setBody:postData];
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

@end
