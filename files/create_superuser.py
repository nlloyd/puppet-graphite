#!/usr/bin/python -W ignore::DeprecationWarning
# -*- encoding: utf-8 -*-

import os
os.environ['DJANGO_SETTINGS_MODULE'] = 'graphite.settings'

from django.contrib.auth.models import User


def check(user):
    return User.objects.filter(username=user)


def main(user, email=None, password=None):
    if not (email and password):
        if check(user):
            print "user %s already exists" % (user,)
            sys.exit(0)
        else:
            sys.exit(1)
    else:
        User.objects.create_superuser(user, email, password)

        print "created user %s" % (user,)


if __name__ == '__main__':
    import sys

    main(*sys.argv[1:])
