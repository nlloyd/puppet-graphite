## reasonable settings for a reasonable OS.  Debian users: you're on your own.
class graphite::web (
    $vhost_host     = '*',
    $vhost_port     = 1081,
    $admin_user     = 'admin',
    $admin_password = 'admin',

    $package        = 'graphite-web',
    $docroot        = '/usr/share/graphite/webapp',
    $logroot        = '/var/log/graphite-web',
    $local_settings = '/etc/graphite-web/local_settings.py',
    $manage_script  = '/usr/lib/python2.6/site-packages/graphite/manage.py',
    $socket_path    = '/var/run/httpd',
    $lib_dir        = '/var/lib/graphite-web'
) {
    require graphite
    require apache::params

    $whisper_data_dir = $graphite::whisper_data_dir

    ## graphite-web package has dependencies provided by Epel, such as Django,
    ## django-tagging
    package {$package: }

    file {$local_settings:
        content => template('graphite/local_settings.py.erb'),

        notify  => Service['httpd'],
        require => Package[$package],
    }

    file {$lib_dir:
        ensure  => directory,
        recurse => true,
        owner   => $apache::params::user,
        group   => $apache::params::group,
    }

    exec {'graphite_syncdb':
        command => "/usr/bin/python ${manage_script} syncdb --noinput",
        user    => $apache::params::user,
        creates => "${lib_dir}/graphite.db",
        require => [
            File[$local_settings],
            File[$lib_dir],
        ],
    }

    $create_user = '/usr/local/bin/create_graphite_superuser.py'

    ## store the create user script on the filesystem
    file {$create_user:
        source => 'puppet:///modules/graphite/create_superuser.py',
        mode   => '0755',
    }

    file {'graphite_wsgi':
        path    => "${docroot}/graphite-web.wsgi",
        content => template('graphite/graphite.wsgi.erb'),
        mode    => '0755',
        notify  => Service['httpd'],
    }

    ## invoke the script to create a superuser
    ## this seems to cause an "integrity error" on first login, but it goes away
    ## after that.
    exec {'create-graphite-superuser':
        environment => "PYTHONPATH=${docroot}",
        user        => $apache::params::user,
        command     => "${create_user} ${admin_user} nobody@home.com ${admin_password}",
        unless      => "${create_user} ${admin_user}",
        require     => [
            File[$create_user],
            Exec['graphite_syncdb'],
        ],
    }

    file {$logroot:
        ensure  => directory,
        owner   => $apache::params::user,
        group   => $apache::params::group,
        recurse => true,
    }

    include apache::mod::wsgi
    apache::vhost {'graphite-web':
        port               => $vhost_port,
        servername         => "${vhost_host}:${vhost_port}",
        docroot            => $docroot,
        configure_firewall => false,
        template           => 'graphite/graphite-web.conf.erb',
        logroot            => $logroot,
        require            => [
            Package[$package],
        ],
    }
}
