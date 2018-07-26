//
//  HLFAQServices.m
//
//
//  Created by Aravinth Chandran on 21/09/15.
//
//

#import "FCFAQServices.h"
#import "FCAPIClient.h"
#import "FCAPI.h"
#import "FCDataManager.h"
#import "FCArticles.h"
#import "FCCategories.h"
#import "FCLocalNotification.h"
#import "FCSecureStore.h"
#import "FCServiceRequest.h"
#import "FCMacros.h"
#import "FCUtilities.h"
#import "FCIndexManager.h"
#import "FCResponseInfo.h"
#import "FCDateUtil.h"
#import "FCTagManager.h"
#import "FCTags.h"
#import "FCUserDefaults.h"
#import "FCLocaleUtil.h"
#import "FCLocaleConstants.h"

@implementation FCFAQServices

-(NSURLSessionDataTask *)fetchAllCategories:(void (^)(NSError *))completion{
    static BOOL CATEGORIES_DOWNLOAD_IN_PROGRESS = NO;
    if (CATEGORIES_DOWNLOAD_IN_PROGRESS) {
        FDLog(@"download solution in progress, so skip");
        if(completion){
            completion(nil);
        }
        return nil;
    }
    CATEGORIES_DOWNLOAD_IN_PROGRESS = YES;
    FCAPIClient *apiClient = [FCAPIClient sharedInstance];
    FCSecureStore *store = [FCSecureStore sharedInstance];
    FCServiceRequest *request = [[FCServiceRequest alloc]initWithMethod:HTTP_METHOD_GET];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *appKey = [store objectForKey:HOTLINE_DEFAULTS_APP_KEY];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_CATEGORIES_PATH,appID];
    NSString *token = [NSString stringWithFormat:HOTLINE_REQUEST_PARAMS,appKey];
    
    NSNumber *lastUpdateTime = [FCUtilities getLastUpdatedTimeForKey:HOTLINE_DEFAULTS_SOLUTIONS_LAST_UPDATED_SERVER_TIME];
    NSNumber *requestlocaleId = [FCLocaleUtil getContentLocaleId];
    NSString *afterTime = [NSString stringWithFormat:PARAM_SINCE,lastUpdateTime];
    NSMutableArray *reqParams = [[NSMutableArray alloc]initWithArray:@[token,afterTime,PARAM_PLATFORM_IOS]];
    [reqParams addObjectsFromArray:[FCLocaleUtil userLocaleParams:NO]];
    [request setRelativePath:path andURLParams:reqParams];
    [request setValue:[lastUpdateTime stringValue]  forHTTPHeaderField:IF_MODIFIED_SINCE];
    
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FCResponseInfo *responseInfo, NSError *error) {
        NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
        if(!error && statusCode == 200) {
            FCDataManager *dataManager = [FCDataManager sharedInstance];
            [dataManager deleteAllFAQ:^(NSError *error) {
                if(!error) {
                    FDLog(@"All faq deleted");
                    [self importSolutions:[responseInfo responseAsDictionary]withCompletion:^(NSError *error) {
                        if(!error && responseInfo){
                            
                            //Updating contentLocaleid and drop voted articles
                            NSMutableDictionary *dictionary = [responseInfo responseAsDictionary][CONTENT_LOCALE];
                            NSNumber *responseLocaleId = [dictionary objectForKey:@"localeId"];
                            if( ![requestlocaleId isEqualToNumber:responseLocaleId] ) {
                                [FCUserDefaults setNumber:responseLocaleId forKey:FC_SOLUTIONS_LAST_RECEIVED_LOCALE];
                                [[FCSecureStore sharedInstance] removeObjectWithKey:HOTLINE_DEFAULTS_VOTED_ARTICLES];
                                FDLog(@"LocaleID changed from %@ -> %@ & Cleared Voted Articles",[FCLocaleUtil getContentLocaleId],responseLocaleId);
                            }
                            
                            //Updating userLocale
                            [FCLocaleUtil updateLocale];
                            
                            NSArray *categories = [responseInfo responseAsDictionary][@"categories"];
                            if(categories && categories.count > 0 ){
                                [FCIndexManager setIndexingCompleted:NO];
                                [FCIndexManager updateIndex];
                            }
                            [FCLocalNotification post:HOTLINE_SOLUTIONS_UPDATED];
                        }
                        if(completion){
                            completion(error);
                            CATEGORIES_DOWNLOAD_IN_PROGRESS = NO;
                            FDLog(@"All solutions hopefully added again.");
                        }
                    }];
                }
                else {
                    CATEGORIES_DOWNLOAD_IN_PROGRESS = NO;
                     if(completion){
                         completion(error);
                         FDLog(@"Problem in adding the new faq.");
                     }
                }
            }];
        }
        else { // 304 not updated also comes here
            if(completion){
                completion(error);
            }
            [FCLocalNotification post:HOTLINE_SOLUTIONS_UPDATED];
            CATEGORIES_DOWNLOAD_IN_PROGRESS = NO;
        }
        
    }];
    return task;
}

-(void)importSolutions:(NSDictionary *)solutions withCompletion:(void (^)(NSError *))completion{
    NSManagedObjectContext *context = [FCDataManager sharedInstance].backgroundContext;
    [context performBlock:^{
        NSArray *categories = solutions[@"categories"];
        for(int i=0; i<categories.count; i++){
            NSDictionary *categoryInfo = categories[i];
            FCCategories *category = [FCCategories getWithID:categoryInfo[@"categoryId"] inContext:context];
            BOOL isCategoryEnabled = [categoryInfo[@"enabled"]boolValue];
            BOOL isIOSPlatformAvail = [categoryInfo[@"platforms"] containsObject:@"ios"];
            NSArray *tags = categoryInfo[@"tags"];
            [FCTags removeTagsForTaggableId:categoryInfo[@"categoryId"] andType:[NSNumber numberWithInt: HLTagTypeCategory] inContext:context];
            if (isCategoryEnabled && isIOSPlatformAvail) {
                if (category) {
                    FDLog(@"Updating category:%@ [%@abled]", categoryInfo[@"title"], ( isCategoryEnabled ? @"en" : @"dis"));
                    [category updateWithInfo:categoryInfo];
                }else{
                    FDLog(@"New category:%@ [%@abled]", categoryInfo[@"title"], ( isCategoryEnabled ? @"en" : @"dis"));
                    category = [FCCategories createWithInfo:categoryInfo inContext:context];
                }
                
                if(tags.count>0){
                    for(NSString *tagName in tags){
                        [FCTags createTagWithInfo:[FCTags createDictWithTagName:tagName type:[NSNumber numberWithInt: HLTagTypeCategory] andIdvalue:categoryInfo[@"categoryId"]] inContext:context];
                    }
                }
            }else{
                if (category){
                    FDLog(@"Deleting category with title : %@ with ID : %@ because its disabled !",category.title, category.categoryID);
                    [context deleteObject:category];
                }
            }
        }
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_CATEGORIES_ENTITY];
        NSArray *allCategories = [context executeFetchRequest:request error:nil];
        for(FCCategories *category in allCategories){
            if(category.articles.count == 0){
                FDLog(@"Deleting category with title : %@ with ID : %@ because it doesn't contain any articles !"
                      ,category.title, category.categoryID);
                [FCTags removeTagsForTaggableId:category.categoryID andType:[NSNumber numberWithInt: HLTagTypeCategory] inContext:context];
                [context deleteObject:category];
            }
        }
        
        NSError *err;
        [context save:&err];
        [[FCSecureStore sharedInstance] setObject:solutions[LAST_MODIFIED_AT] forKey:HOTLINE_DEFAULTS_SOLUTIONS_LAST_UPDATED_SERVER_TIME];
        if(completion){
            completion(err);
        }
    }];
}

-(NSURLSessionDataTask *)vote:(BOOL)vote forArticleID:(NSNumber *)articleID inCategoryID:(NSNumber *)categoryID{
    FCAPIClient *apiClient = [FCAPIClient sharedInstance];
    FCSecureStore *store = [FCSecureStore sharedInstance];
    FCServiceRequest *request = [[FCServiceRequest alloc]initWithMethod:HTTP_METHOD_PUT];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_ARTICLE_VOTE_PATH,appID,categoryID,articleID];
    NSString *appKey = [store objectForKey:HOTLINE_DEFAULTS_APP_KEY];
    NSString *token = [NSString stringWithFormat:HOTLINE_REQUEST_PARAMS,appKey];
    NSMutableArray *reqParams = [[NSMutableArray alloc]initWithArray:@[token,PARAM_PLATFORM_IOS]];
    [reqParams addObjectsFromArray:[FCLocaleUtil userLocaleParams:YES]];
    [request setRelativePath:path andURLParams:reqParams];
    NSDictionary *voteInfo;
    if (vote) {
        voteInfo = @{ @"upvote" : @1 };
    }else{
        voteInfo = @{ @"downvote" : @1 };
    }
    NSData *postData = [NSJSONSerialization dataWithJSONObject:voteInfo options:0 error:nil];
    [request setBody:postData];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FCResponseInfo *responseInfo,NSError *error) {
        NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
        if(!error && statusCode == 200) {
            FDLog(@"Article vote successful");
        }else{
            FDLog(@"Article voting failed :%@", error);
            FDLog(@"Response %@", responseInfo.response);
        }
    }];
    return task;
}

@end
