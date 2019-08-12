//
//  HLCategory.m
//  
//
//  Created by Aravinth Chandran on 21/09/15.
//
//

#import "FCCategories.h"
#import "FCArticles.h"
#import "FCDataManager.h"
#import "FCMacros.h"
#import "FCTagManager.h"
#import "FCTags.h"
#import "FCUtilities.h"
#import "FCVotingManager.h"
#import "FCSecureStore.h"

@implementation FCCategories

@dynamic categoryDescription;
@dynamic categoryID;
@dynamic icon;
@dynamic position;
@dynamic title;
@dynamic articles;
@dynamic iconURL;
@dynamic lastUpdatedTime;
@dynamic categoryAlias;

+(FCCategories *)getWithID:(NSNumber *)categoryID inContext:(NSManagedObjectContext *)context{
    FCCategories *category = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_CATEGORIES_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"categoryID == %@",categoryID];
    NSArray *matches             = [context executeFetchRequest:fetchRequest error:nil];
    if (matches.count == 1) {
        category = matches.firstObject;
    }
    if (matches.count > 1) {
        category = nil;
        FDLog(@"Duplicates found in Category table !");
    }
    return category;
}

+(FCCategories *)createWithInfo:(NSDictionary *)categoryInfo inContext:(NSManagedObjectContext *)context{
    FCCategories *category = [NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_CATEGORIES_ENTITY inManagedObjectContext:context];
    return [self updateCategory:category withInfo:categoryInfo];
}

-(void)updateWithInfo:(NSDictionary *)categoryInfo{
    [FCCategories updateCategory:self withInfo:categoryInfo];
}

+(FCCategories *)updateCategory:(FCCategories *)category withInfo:(NSDictionary *)categoryInfo{
    NSManagedObjectContext *context = category.managedObjectContext;
    category.categoryID          = categoryInfo[@"categoryId"];
    category.title               = categoryInfo[@"title"];
    category.iconURL             = categoryInfo[@"icon"];
    category.position            = categoryInfo[@"position"];
    category.lastUpdatedTime     = [NSDate dateWithTimeIntervalSince1970:[categoryInfo[@"lastUpdatedAt"]doubleValue]];
    category.categoryDescription = categoryInfo[@"description"];
    category.categoryAlias       = categoryInfo[@"categoryAlias"];
    if(category.iconURL){
        [FCUtilities cacheImageWithUrl:category.iconURL];
    }
    
    //Update article if exist or create a new one
    NSArray *articles =  categoryInfo[@"articles"];
    NSNumber *faqLastUpdatedTime = [FCUtilities getLastUpdatedTimeForKey:HOTLINE_DEFAULTS_SOLUTIONS_LAST_UPDATED_SERVER_TIME];
    for (int j=0; j<articles.count; j++) {
        NSDictionary *articleInfo = articles[j];
        NSNumber *articleId = articleInfo[@"articleId"];
        FCArticles *article = [FCArticles getWithID:articleId inContext:context];
        BOOL isArticleEnabled = [articleInfo[@"enabled"]boolValue];
        BOOL isIOSPlatformAvail = [articleInfo[@"platforms"] containsObject:@"ios"];
        NSArray *tags = articleInfo[@"tags"];
        [FCTags removeTagsForTaggableId:articleId andType:[NSNumber numberWithInt: HLTagTypeArticle] inContext:context];
        if (isArticleEnabled && isIOSPlatformAvail) {
            if (article) {
                [article updateWithInfo:articleInfo];
                article.category = [FCCategories getWithID:article.categoryID inContext:context];
            }else{
                article = [FCArticles createWithInfo:articleInfo inContext:context];
                [category addArticlesObject:article];
            }
            //Compare sol. last upate with article to clear existing voting
            if(faqLastUpdatedTime &&
               ([articleInfo[@"lastUpdatedAt"] doubleValue] > [faqLastUpdatedTime doubleValue])){
                    [self updateRatingsForArticle:articleId];
            }
            if(tags.count>0){
                for(NSString *tagName in tags){
                    
                    [FCTags createTagWithInfo:[FCTags createDictWithTagName:tagName type:[NSNumber numberWithInt: HLTagTypeArticle] andIdvalue:articleId] inContext:context];
                }
            }
        }else{
            if (article){
                FDLog(@"Deleting article with title : %@ with ID : %@ because its disabled !",article.title, article.articleID);
                [context deleteObject:article];
            }
            else {
               FDLog(@"Skipping article with title : %@ with ID : %@ because its disabled !",articleInfo[@"title"], articleInfo[@"articleId"]);
            }
        }
    }
    return category;
}

+ (void) updateRatingsForArticle : (NSNumber *)articleId{
    BOOL isArticleVoted = [[FCVotingManager sharedInstance] isArticleVoted:articleId];
    if(isArticleVoted){
        [[FCVotingManager sharedInstance] clearVotingForArticle:articleId];
    }
}

@end
