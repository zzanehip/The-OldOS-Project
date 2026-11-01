//
//  MCOIMAPCustomCommandOperation.h
//  mailcore2
//
//  Created by Libor Huspenina on 29/10/2015.
//  Copyright © 2015 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOIMAPCUSTOMCOMMANDOPERATION_H

#define MAILCORE_MCOIMAPCUSTOMCOMMANDOPERATION_H

#import <MailCore/MCOIMAPBaseOperation.h>
#import <MailCore/MCOConstants.h>

NS_ASSUME_NONNULL_BEGIN
@interface MCOIMAPCustomCommandOperation : MCOIMAPBaseOperation

- (void)start:(void(^)(NSString * __nullable response, NSError * __nullable error))completionBlock;

@end
NS_ASSUME_NONNULL_END

#endif
