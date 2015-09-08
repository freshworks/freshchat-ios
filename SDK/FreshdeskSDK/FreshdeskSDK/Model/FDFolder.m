//
//  FDFolder.m
//  FreshdeskSDK
//
//  Created by AravinthChandran on 31/10/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDFolder.h"
#import "FDArticle.h"
#import "MobiHelpDatabase.h"
#import "FDAPI.h"

@implementation FDFolder

@dynamic categoryID;
@dynamic categoryName;
@dynamic folderDescription;
@dynamic folderID;
@dynamic name;
@dynamic position;
@dynamic articles;
@dynamic categoryPosition;

+(FDFolder *)folderWithInfo:(NSDictionary *)fetchedInfo inManagedObjectContext:(NSManagedObjectContext *)context{
    FDFolder *folder = nil;
    folder = [NSEntityDescription insertNewObjectForEntityForName:MOBIHELP_DB_FOLDER_ENTITY inManagedObjectContext:context];
    folder.folderID          = fetchedInfo[@"id"];
    folder.name              = fetchedInfo[@"name"];
    folder.position          = fetchedInfo[@"position"];
    folder.categoryID        = fetchedInfo[@"category_id"];
    folder.categoryName      = fetchedInfo[@"category_name"];
    folder.categoryPosition  = fetchedInfo[@"category_position"];
    folder.folderDescription = fetchedInfo[@"description"];
    return folder;
}

@end