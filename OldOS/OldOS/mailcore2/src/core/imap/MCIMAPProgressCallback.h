#ifndef MAILCORE_MCIMAPPROGRESSCALLBACK_H

#define MAILCORE_MCIMAPPROGRESSCALLBACK_H

#ifdef __cplusplus

#include <MailCore/MCUtils.h>

namespace mailcore {
    
    class IMAPSession;
    
    class MAILCORE_EXPORT IMAPProgressCallback {
    public:
        virtual void bodyProgress(IMAPSession * session, unsigned int current, unsigned int maximum) {};
        virtual void itemsProgress(IMAPSession * session, unsigned int current, unsigned int maximum) {};
    };
    
}

#endif

#endif
