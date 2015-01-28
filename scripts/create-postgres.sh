#!/usr/bin/env bash

DB=$1;
USERNAME="$2"
PASSWORD="$3"
su postgres -c "dropdb $USERNAME --if-exists"
su postgres -c "createdb -O $USERNAME '$DB'"
