
# puppet-graphite

A quick and (really) dirty module for managing Graphite with Puppet.

## creating packages

### rpm

Use [these excellent spec files](https://github.com/dcarley/graphite-rpms).

### deb

Debian's packaging system is a steaming turd.  I've not found a good set of packages that puts things in the right locations per the RPMs above.  [fpm](https://github.com/jordansissel/fpm) does a good job, but there's no startup script.  This Puppet module will provide an upstart script if you cannot afford your own.  

Here's the fpm incantation for creating `.deb`s:

    fpm -s python -t deb \
        --python-package-name-prefix python2.7 \
        --depends "python" \
        -v 0.9.10 whisper
    
    ## python-install-bin avoids later jiggery pokery with PYTHONPATH and
    ## GRAPHITE_CONF_DIR environment variables when starting carbon-cache.py
    fpm -s python -t deb \
        --python-package-name-prefix python2.7 \
        --python-install-bin /opt/graphite/bin \
        --depends "python" \
        --depends "python-twisted" \
        --depends "python2.7-whisper" \
        -v 0.9.10 carbon
    
    ## same thing with python-install-bin here; there's nothing of great use
    ## that should get installed to /usr/bin
    fpm -s python -t deb \
        --python-package-name-prefix python2.7 \
        --python-install-bin /opt/graphite/bin \
        --depends "python" \
        --depends "python2.7-whisper" \
        --depends "python-twisted" \
        --depends "python-cairo" \
        --depends "python-django" \
        --depends "python-django-tagging" \
        -v 0.9.10 graphite-web

Stick those in a repo.

## configuration

Reasonable defaults have been provided for Carbon, but the Graphite web app is
harder to do consistently given the packaging morass (see above).  Additionally,
the names of the packages must be provided if you're on a Debian-based system.

### minimal, rpm

    {
        "graphite::carbon::package": "python2.7-carbon",
        "graphite::web::package":    "python2.7-graphite-web",

        "graphite::whisper_data_dir": "/var/lib/carbon/whisper/",

        "graphite::carbon::provide_init_script": true,
        
        "graphite::web::docroot":        "/opt/graphite/webapp",
        "graphite::web::local_settings": "/opt/graphite/webapp/graphite/local_settings.py",
        "graphite::web::manage_script":  "/opt/graphite/webapp/graphite/manage.py",
        "graphite::web::socket_path":    "/var/run/apache2"
    }

### minimal, deb

    {
        "graphite::whisper_data_dir": "/var/lib/carbon/whisper/",
    }
