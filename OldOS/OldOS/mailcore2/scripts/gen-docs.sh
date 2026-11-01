#!/bin/sh

if test -f prepare.sh ; then
  cd ..
fi

appledoc \
--no-create-docset \
--no-install-docset \
--project-name MailCore2 \
--project-company "MailCore2" \
--company-id com.mailcore2 \
--logformat xcode \
--ignore "*.m" \
--no-warn-invalid-crossref \
--no-repeat-first-par \
--output appledoc \
src
