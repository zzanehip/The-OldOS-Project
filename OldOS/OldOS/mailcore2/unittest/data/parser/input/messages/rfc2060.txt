From: me@myself.com
To: me@myself.com
Subject: Sample message structure for IMAP part specifiers
MIME-Version: 1.0
Content-Type: MULTIPART/MIXED; boundary="x"

--x
Content-Type: TEXT/PLAIN

This part specifier should be: 1

--x
Content-Type: APPLICATION/OCTET-STREAM

This part specifier should be: 2

--x
Content-Type: MESSAGE/RFC822

From: me@myself.com
To: me@myself.com
Subject: This part specifier should be: 3
MIME-Version: 1.0
Content-Type: MULTIPART/MIXED; boundary="3.x"

--3.x
Content-Type: TEXT/PLAIN

This part specifier should be: 3.1

--3.x
Content-Type: APPLICATION/OCTET-STREAM

This part specifier should be: 3.2

--3.x--
--x
Content-Type: MULTIPART/MIXED; boundary="4.x"

--4.x
Content-Type: IMAGE/GIF

This part specifier should be: 4.1

--4.x
Content-Type: MESSAGE/RFC822

From: me@myself.com
To: me@myself.com
Subject: This part specifier should be: 4.2
MIME-Version: 1.0
Content-Type: MULTIPART/MIXED; boundary="4.2.x"

--4.2.x
Content-Type: TEXT/PLAIN

This part specifier should be: 4.2.1

--4.2.x
Content-Type: MULTIPART/ALTERNATIVE; boundary="4.2.2.x"

--4.2.2.x
Content-Type: TEXT/PLAIN

This part specifier should be: 4.2.2.1

--4.2.2.x
Content-Type: TEXT/RICHTEXT

This part specifier should be: 4.2.2.2

--4.2.2.x--
--4.2.x--
--x--
