#! /bin/sh

if [[ ! -s /etc/prod ]] ; then
    # Not on WCOSS.  No dev vs. prod, so we're always "on dev"
    "$@"
else
    hostchar=$( hostname | head -1 | cut -c1-1 )
    prodchar=$( head -1 /etc/prod | cut -c1-1 )
    
    if [[ "$hostchar" != "$prodchar" ]] ; then
        # This is the dev side.
        "$@"
    else
        echo "On production machine." 1>&2
    fi
fi