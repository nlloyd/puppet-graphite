## reasonable settings for a reasonable OS.  Debian users: you're on your own.
class graphite::carbon(
    $cache_port       = 2003,
    $cache_enable_udp = false,
    $cache_udp_port   = 2003,
    
    $package             = 'carbon',
    $conf_dir            = '/etc/carbon',
    $storage_dir         = '/var/lib/carbon/',
    $log_dir             = '/var/log/carbon/',
    $provide_init_script = false,
    
    $schemas     = 'puppet:///modules/graphite/storage-schemas.conf',
    $aggregation = undef,
) {
    require graphite

    ## local variable definition required for carbon.conf.erb
    ## NO TOUCHY!!!
    $whisper_data_dir = $graphite::whisper_data_dir
    
    package {$package : }
    
    File {
        owner => 'carbon',
        group => 'carbon',
    }
    
    if $provide_init_script {
        file {'/etc/init/carbon-cache.conf':
            content => template('graphite/upstart-carbon.conf.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            require => Package[$package],
            before  => Service['carbon-cache'],
            notify  => Service['carbon-cache'],
        }
    }
    
    user {'carbon':
        ensure => present,
        system => true,
    }
    
    file {[
        $conf_dir,
        $log_dir,
    ]:
        ensure  => directory,
        recurse => true,
    }
    
    ## these are too big and deep to be recursed into without killing Puppet
    ## performance (and possibly Puppet altogether)
    file {[
        $storage_dir,
        $whisper_data_dir,
    ]:
        ensure  => directory,
    }

    file {"${conf_dir}/carbon.conf":
        content => template('graphite/carbon.conf.erb'),
        require => Package[$package],
        notify  => Service['carbon-cache'],
    }

    file {"${conf_dir}/storage-schemas.conf":
        source  => $schemas,
        require => Package[$package],
        notify  => Service['carbon-cache'],
    }
    
    if $aggregation == undef {
        file {"${conf_dir}/storage-aggregation.conf":
            ensure  => absent,
            require => Package[$package],
            notify  => Service['carbon-cache'],
        }
    } else {
        file {"${conf_dir}/storage-aggregation.conf":
            source  => $aggregation,
            require => Package[$package],
            notify  => Service['carbon-cache'],
        }
    }
    
    service {'carbon-cache':
        ensure  => running,
        enable  => true,

        require => [
            Package[$package],
            User['carbon'],
        ],
    }
}
