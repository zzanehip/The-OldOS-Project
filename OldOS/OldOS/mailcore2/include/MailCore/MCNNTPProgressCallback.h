#ifndef MAILCORE_MCNNTPPROGRESSCALLBACK_H

#define MAILCORE_MCNNTPPROGRESSCALLBACK_H

#ifdef __cplusplus

#include <MailCore/MCUtils.h>

namespace mailcore {
    
    class NNTPSession;
    
    class MAILCORE_EXPORT NNTPProgressCallback {
    public:
        virtual void bodyProgress(NNTPSession * session, unsigned int current, unsigned int maximum) {};
    };
    
}

#endif

#endif
