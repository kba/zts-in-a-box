# zts-in-a-box
Zotero Translation Server + Simple Scraping API + Swagger in Docker

[![Build Status](https://travis-ci.org/kba/zts-in-a-box.svg?branch=master)](https://travis-ci.org/kba/zts-in-a-box)

<!-- BEGIN-MARKDOWN-TOC -->
* [Introduction](#introduction)
* [Installation](#installation)
* [Configuration](#configuration)
	* [`ZTS_DOCKER_IMAGE`](#zts_docker_image)
	* [`ZTS_DOCKER_TAG`](#zts_docker_tag)
	* [`ZTS_PORT`](#zts_port)
	* [`ZTS_HOST`](#zts_host)
		* [Linux](#linux)
		* [Windows 10 (Hyper-V)](#windows-10-hyper-v)
		* [MacOSX / Windows 7 / Windows 8 / Windows 10 (docker-toolbox)](#macosx--windows-7--windows-8--windows-10-docker-toolbox)
			* [Easy method](#easy-method)
			* [Manual method](#manual-method)
		* [Hosted](#hosted)
			* [Apache](#apache)
			* [nginx](#nginx)
	* [`ENABLE_CACHE`](#enable_cache)
* [Usage](#usage)
* [Development](#development)
	* [Node JS component](#node-js-component)
* [FAQ](#faq)
	* [I forgot the `--recursive` flag when cloning](#i-forgot-the---recursive-flag-when-cloning)
	* [All log lines start with a combination of weird characters (Windows)](#all-log-lines-start-with-a-combination-of-weird-characters-windows)

<!-- END-MARKDOWN-TOC -->

## Introduction

The aim of this project is to make the [Zotero Translation
Server](https://github.com/zotero/translation-server) easier to deploy and more
comfortable to work with.

The project consists of four components:

* The translation server, packaged as a [Docker image](https://hub.docker/com/r/kbai/zts)
* A small [Node JS server](./src/lib/) that offers a simple API for the use
  case of scraping a website and exporting the results in one go. It also acts
  as a proxy to the translation server and Swagger UI
* An [API user interface](./zts.swagger.yml) that describes the services and
  powers a web site to try out all endpoints, courtesy of [Swagger
  UI](https://hub.docker.com/r/sjeandeaux/docker-swagger-ui)
* The [Zotero translators](https://github.com/zotero/translators), the many,
  many scripts that scrape web pages for bibliographic data and make Zotero so
  versatile. The system is set up to use the [`./translators` Git
  submodule](./translators/) instead of the bundled version of the translators
  that come with translation server. This makes it easier to test script
  problems and allows you to deploy updates as they happen in Github.

## Installation

There are only two hard requirements for getting zts-in-a-box up and running:

* [Docker](https://docs.docker.com/engine/installation/)
* [Docker Compose](https://docs.docker.com/compose/install/)

Once you have them installed, clone this repository and build/pull the containers:

```sh
git clone --recursive https://github.com/kba/zts-in-a-box
cd zts-in-a-box
docker-compose pull
docker-compose build
```

This will:

* Create a bridge network for the containers to communicate
* Pull the Docker images for the translation server and Swagger UI
* Build the Node JS application into a Docker image

Once everything is built and pulled and ready, proceed to configure:

## Configuration

The configuration and orchestration of the containers is defined by the
`docker-compose.yml` file. It will pass on environment variables to the
containers to configure their behavior.

You should **not need to edit** the `docker-compose.yml` file directly unless
you are developing zts-in-a-box itself.

Instead adapt the variable definitions in [`.env`](./.env) that define how
`docker-compose` sets up the containers.

Every line is a key-value pair, Lines starting with `#` are ignored.

### `ZTS_DOCKER_IMAGE`

Default: **`kbai/zts`**

The docker image on hub.docker.com to use

Only change this if you want to use your own custom built Zotero Translation
Server docker image

### `ZTS_DOCKER_TAG`

Default: **`46.0`**

The version of the Zotero Translation Server image

Only need to change this for debugging translators

### `ZTS_PORT`

Default: **`1970`**

The port that will forward to the internal port.

No need to change this unless the default **1970** is already taken on the host.

### `ZTS_HOST`

Default: **`ZTS_HOST`**

The externally visible name that will be used for all URL in the
application. This is what you will need to type into the browser
address bar to access the application.

The value depends on your operating system and whether you are running
zts-in-a-box from your local PC or within a network.

#### Linux

No need to change anything, the defaults will work and the application
is available at [http://localhost:1970](http://localhost:1970).

#### Windows 10 (Hyper-V)

In more recent versions of Windows 10, docker can run natively if the Hyper-V
hypervisor is enabled. It should then behave exactly like a [Linux](#linux)
system.

#### MacOSX / Windows 7 / Windows 8 / Windows 10 (docker-toolbox)

On all of these operating systems, docker is not run natively but uses
VirtualBox as the hypervisor. This additional level of indirection requires the
application to be accessed by the IP of the virtual machine running docker
instead of the host IP/hostname.

##### Easy method

The script [`update-host.sh`](./script/update-host.sh) will set `ZTS_HOST` to
the correct IP/port combination in `.env`.

```sh
./script/update-host.sh [name-of-docker-machine]
```

`name-of-docker-machine` is the name of the **docker machine** that runs the
docker engine.  If omitted, it tries looks for the `DOCKER_MACHINE` environment
variable and falls back to `"default"`.

The script will update [`.env`](./.env) with the correct `ZTS_HOST` and output
the HTTP URL where the application will be available.

Whenever the IP address of the docker machine changes (e.g. after a reboot),
run:

```sh
./script/update-host.sh
docker-compose up -d
```

##### Manual method

Find out the IP of the **virtual machine** that hosts the docker engine:

```sh
docker-machine ip <name-of-machine>
```

This will yield something like `192.168.99.xxx`.

Then change the `ZTS_HOST` entry in [`.env`](./.env) accordingly:

```sh
ZTS_HOST=192.168.99.100:1970
```

The application is then available at
[http://192.168.99.100:1970](http://192.168.99.100:1970).

#### Hosted

If you want to run zts-in-a-box on a server that should be accessible on the
Internet, set `ZTS_HOST` to the base URL from where it will be accessible.

Suppose you are running a web server on `mybox.tld` and zts-in-a-box should be
accessible at  `/zotero/`, then you should adapt [`.env`](./.env) to contain

```sh
ZTS_HOST=http://mybox.tld/zotero/
```

You still will need to forward traffic on incoming port `80` to/from the
[`ZTS_PORT`](#zts_port), which defaults to `1970`.

##### Apache

```apache
  <Location /zotero/>
    ProxyPass http://localhost:1970/ retry=0
    ProxyPassReverse http://localhost:1970/
  </Location>
```

##### nginx

```nginx
server {
    listen 80;

    server_name mybox.tld;

    location /zotero/ {
        proxy_pass http://localhost:1970;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### `ENABLE_CACHE`

Default: **`true`**

If enabled, zts-in-a-box will cache requests to the
[Simple Scraper API](http://localhost:1970/#!/Simple_Scraper_API). This vastly
reduces network traffic and computing power for possibly redundant requests. If
the same URL is to be scraped and exported to the same format, the cached
results are returned right away.

You can empty the cache by running a `DELETE` request to
`$ZTS_HOST/simple/cache` without completely disabling it.

The only reason why you would **not** want result caching is if you are
developing / debugging a translator.

## Usage

With all configuration finished, start the containers to run persistently in the background:

```sh
docker-compose up -d
```

To see what is happening, use the `logs` command of `docker-compose`:

```sh
docker-compose logs -f
```

Once they are booted, you can navigate to
[http://localhost:1970](http://localhost:1970) (or whatever you set `ZTS_HOST`
to):

![Swagger UI](./doc/screenshot/swagger.png)

You can try all the API endpoints. For example, to get a Bibtex reference from
an online article:

1. Click on [Simple_Scraper_API](http://localhost:1970/#!/Simple_Scraper_API)
2. Click on [GET /simple/](http://localhost:1970/#!/Simple_Scraper_API/get_simple)
3. Set `format` to `bibtex`
4. Choose an interesting article, eg.
   [DOI:10.1016/j.mehy.2009.01.015](http://www.sciencedirect.com/science/article/pii/S0306987709000474)
   and paste its URL into the `url` field.
5. Click `Try it out` and wait a few moments. The bibtex formatted citation
   should be the `Response Body` field.
6. Click `Try it out` again. It should respond almost instantaneous since the
   result has been cached.

## Development

### Node JS component

Use the [`docker-compose.dev.yml`](./docker-compose.dev.yml) extended compose file:

```
docker-compose -f docker-compose.dev.yml up
```

This will mount the CoffeeScript source and restart the server whenever the
source changes.

## FAQ

### I forgot the `--recursive` flag when cloning

```sh
git submodule init
git submodule update
```

### All log lines start with a combination of weird characters (Windows)

If the output from `docker-compose` is monochrome and seems garbled, your
terminal emulator does not support ANSI color codes. Either use a terminal
emulator that does or add the `--no-color` flag to all `docker-compose` calls.
