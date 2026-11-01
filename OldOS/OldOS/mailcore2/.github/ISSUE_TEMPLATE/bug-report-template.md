---
name: Bug report template
about: Describe this issue template's purpose here.
title: "[Bug] - "
labels: bug
assignees: ''

---

**Summary**

**Platform(s)**
```
<Android>
```

**Happens on Mail Server**
```
<Gmail>
<iCloud>
```

**Piece of code**
```
MCOIMAPSession *session = [[MCOIMAPSession alloc] init];
[session setHostname:@"imap.gmail.com"];
[session setPort:993];
[session setUsername:@"ADDRESS@gmail.com"];
[session setPassword:@"123456"];
[session setConnectionType:MCOConnectionTypeTLS];
```

**Actual outcome**
MailCore did or did not ...

**Connection Logs**
```
* ID ("name" "GImap" "vendor" "Google, Inc." "support-url" "https://support.google.com/mail" "version" "gmail_imap_200623.09_p0" "remote-host" "2001:ee0:4fc
5:b6e0:d410:e4d3:77db:fc8e
```

**Expected outcome**
MailCore should ...

**Link to sample code on GitHub reproducing the issue (a full Xcode project):**
```
https://
```
