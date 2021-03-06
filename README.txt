python-django-repomgmt

This Django app implements everything you need to create APT repositories,
buildd infrastructure as well as automatic package building.

It expects access to an OpenStack Compute cloud to perform builds and uses
reprepro on the backend to manage the APT repositories, process incoming,
etc.

Setting it up should be fairly simple.

You need Django, django-tastypie, django-celery, sbuild and devscripts
installed.

These are the configuration options you need to add to your settings.py:

APT_REPO_BASE_URL

    The base URL by which your repositories will be reachable.

    E.g. if set to http://apt.example.com/, it's assumed that
    your web server is configured to expose e.g. the "cisco" repository
    under http://apt.example.com/cisco

POST_MK_SBUILD_CUSTOMISATION

    An argv to be executed in the schroot after mk-sbuild is done.

    E.g. to avoid using a proxy for a apt.example.com, you can do
    something like:

    POST_MK_SBUILD_CUSTOMISATION = ['bash', '-c', 'echo \'Acquire::HTTP::Proxy::apt.example.com "DIRECT";\' > /etc/apt/apt.conf.d/99noproxy']

BASE_URL

    The base URL of the repomgmt app. This is used to construct URLs
    where build nodes can fetch their puppet manifest.

BASE_TARBALL_URL

    A URL where the generated tarballs can be found. The tarballs generally
    land in /var/lib/schroot/tarballs, so you should configure a web server to
    serve that directory at this URL.

BASE_REPO_DIR

    The base directory where the repositories should be kept.
    Each repository will be represented by a subdirectory here.

BASE_PUBLIC_REPO_DIR

    A directory holding the public parts of the repo.

BASE_INCOMING_DIR

    The base dir used for incoming dirs.

FTP_IP

    IP where builders can send back built packages.

FTP_BASE_PATH

    Base path where packages can be put.


TESTING

    If set to True, repomgmt will be in testing mode and won't write anything
    to disk.

It is also expected that django-celery is already configured. This should be as simple as adding something like this near the end of your settings.py:

    INSTALLED_APPS += ("djcelery", )
    import djcelery
    djcelery.setup_loader()

    BROKER_URL = 'amqp://guest:guest@localhost:5672/'

You also need to add the django.contrib.humanize app to INSTALLED_APPS.

= Quickly establishing a development environment =

A simple Puppet module is included, mostly intended for development purposes.
Fire up a fresh, clean Ubuntu VM and log in.

(This is a dump of my copy/paste file for this, it's not meant as a script)

sudo apt-get -y install git puppet
git clone https://github.com/sorenh/python-django-repomgmt
sudo -H puppet apply --modulepath python-django-repomgmt/puppet python-django-repomgmt/puppet/repomgmt/tests/install.pp 
logout
ssh back in
cd buildd
screen -dmS www bash -c 'python manage.py runserver 0.0.0.0:8000'
screen -dmS celeryworker1 bash -c 'python manage.py celery worker -B --autoreload'

