class repomgmt($user = 'buildd',
               $port = '80',
               $hostname,
               $priority = '30',
               admin_name => "Admin User",
               admin_email => "email@example.com"
               dbname => "repomgmt",
               dbuser => "repomgmt",
               dbpass => "repomgmtpass",
               dbhost => "",
               dbport => ""
               secret_key => '!tuy9ozxr@zhr$8v3$41^3690dfnrim16yj8x5)4pi0bg%140l',
               ftp_ip => $::ipaddress,
               ) {
  
  include apache 

  $simple = false;

  apache::vhost { "repomgmt":
    priority           => $priority,
    port               => $port,
    template           => "repomgmt/apache.site.erb",
    doctroot           => "/home/$user/www",
    configure_firewall => false
  }

  package { ["python-pip",
             "devscripts",
             "sbuild",
             "git",
             "rabbitmq-server",
             "ubuntu-dev-tools",
             "reprepro",
             "haveged",
             "vsftpd"]:
    provider => "apt",
    ensure => "installed",
  }

  package { ["Django",
             "django-celery",
             "django-tastypie",
             "python-novaclient",
             "south"]:
    provider => "pip",
    ensure => "installed",
    require => Package['python-pip']
  }

  mysql::db { "$dbname":
    user     => "$dbuser",
    password => "$dbpass",
    host     => 'localhost',
    grant    => ['all'],
  }

  exec { "/usr/bin/pip install -e git+http://github.com/sorenh/python-django-repomgmt#egg=django-repomgmt":
    require => [Package['git'], Package['python-pip']]
  }

  user { "$user":
    ensure => "present",
    managehome => true,
    groups => "sbuild",
    require => Package['sbuild']
  }

  exec { "/usr/local/bin/django-admin.py startproject www":
    creates => "/home/$user/www",
    cwd => "/home/$user",
    user => $user
  } ->
  file { "/home/$user/www/www/settings.py":
    content => template('repomgmt/settings.py.erb'),
    owner => $user
  } ->
  file { "/home/$user/www/www/urls.py":
    content => template('repomgmt/urls.py.erb'),
    owner => $user
  } ~>
  exec { "/usr/bin/python /home/$user/www/manage.py syncdb --noinput":
    user => $user,
    refreshonly => true
  }

  file { "/etc/vsftpd.conf":
    content => template('repomgmt/vsftpd.conf.erb'),
    mode => 0644,
    owner => root,
    group => root,
    require => Package[vsftpd],
    notify => Exec["reload-vsftpd"]
  } 

  file { "/srv/ftp/incoming":
    ensure => directory,
    owner => $user,
    group => ftp,
    mode => "2711",
    require => Package[vsftpd],
  }

  exec { "reload-vsftpd":
    command => "/sbin/restart vsftpd",
    refreshonly => true
  }
}
