//
//  Article.h
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 27/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FDFolder;

@interface FDArticle : NSManagedObject

@property (nonatomic, retain) NSString * articleDescription;
@property (nonatomic, retain) NSNumber * articleID;
@property (nonatomic, retain) NSNumber * position;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * descriptionPlainText;
@property (nonatomic, retain) FDFolder *folder;

+(FDArticle *)articleWithInfo:(NSDictionary *)articleInfo inManagedObjectContext:(NSManagedObjectContext *)context;

+(FDArticle *)getArticleWithID:(NSNumber *)articleID inManagedObjectContext:(NSManagedObjectContext *)context;

@end
