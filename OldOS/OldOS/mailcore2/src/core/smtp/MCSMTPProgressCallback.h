#ifndef MAILCORE_MCSMTPPROGRESSCALLBACK_H

#define MAILCORE_MCSMTPPROGRESSCALLBACK_H

#ifdef __cplusplus

#include <MailCore/MCUtils.h>

namespace mailcore {
    
    class SMTPSession;
    
    class MAILCORE_EXPORT SMTPProgressCallback {
    public:
        virtual void bodyProgress(SMTPSession * session, unsigned int current, unsigned int maximum) {};
    };
    
}

#endif

#endif
