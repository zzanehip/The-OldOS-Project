//
//  IMAPMoveMessagesOperation.hpp
//  mailcore2
//
//  Created by Nikolay Morev on 02/02/16.
//  Copyright © 2016 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCIMAPMOVEMESSAGESOPERATION_H

#define MAILCORE_MCIMAPMOVEMESSAGESOPERATION_H

#include <MailCore/MCIMAPOperation.h>

#ifdef __cplusplus

namespace mailcore {

    class MAILCORE_EXPORT IMAPMoveMessagesOperation : public IMAPOperation {
    public:
        IMAPMoveMessagesOperation();
        virtual ~IMAPMoveMessagesOperation();

        virtual void setDestFolder(String * destFolder);
        virtual String * destFolder();

        virtual void setUids(IndexSet * uids);
        virtual IndexSet * uids();

        // Result.
        virtual HashMap * uidMapping();

    public: // subclass behavior
        virtual void main();

    private:
        IndexSet * mUids;
        String * mDestFolder;
        HashMap * mUidMapping;
    };

}

#endif

#endif
