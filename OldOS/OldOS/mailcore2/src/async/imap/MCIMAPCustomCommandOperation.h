//
//  MCIMAPCustomCommandOperation.h
//  mailcore2
//
//  Created by Libor Huspenina on 18/10/2015.
//  Copyright © 2015 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCIMAPCUSTOMCOMMANDOPERATION_H

#define MAILCORE_MCIMAPCUSTOMCOMMANDOPERATION_H

#include <MailCore/MCIMAPOperation.h>

#ifdef __cplusplus

namespace mailcore {

    class MAILCORE_EXPORT IMAPCustomCommandOperation : public IMAPOperation {
    public:
        IMAPCustomCommandOperation();
        virtual ~IMAPCustomCommandOperation();

        virtual void setCustomCommand(String *command);
        virtual String * response();

    public: // subclass behavior
        virtual void main();

    private:
        String * mCustomCommand;
        String * mResponse;
    };

}

#endif

#endif
