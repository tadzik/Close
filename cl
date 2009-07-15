#! /bin/sh
BEFORE_ARGS=""
AFTER_ARGS=""

#set -x

for arg
do
	if [ ! "$sharg" ]
	then
		case "$arg" in
		-L*)	BEFORE_ARGS="$BEFORE_ARGS $arg"	;;
		-t )	BEFORE_ARGS="$BEFORE_ARGS $arg" ; sharg=BEFORE ;;
		* )	AFTER_ARGS="$AFTER_ARGS $arg" ;;
		esac
	else
		case "$sharg" in
		BEFORE)	BEFORE_ARGS="$BEFORE_ARGS $arg"	;;
		* )	AFTER_ARGS="$AFTER_ARGS $arg" ;;
		esac
	
		sharg=""
	fi
done

parrot $BEFORE_ARGS -Llibrary/close -r close.pbc $AFTER_ARGS
