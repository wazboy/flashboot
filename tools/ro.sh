#!/bin/sh
#
# $Id: ro.sh,v 1.2 2008/01/14 12:26:26 jakob Exp $

DEV=`df | grep /flash | sed 's/\(^\/dev\/[a-z0-9]*\).*/\1/g'`

mount -u -o ro $DEV /flash
