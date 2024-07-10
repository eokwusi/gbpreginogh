#!/bin/bash
set -e

TOTAL_EXECUTION_START_TIME=$SECONDS
SOURCE_DIR="$1"
DESTINATION_DIR="$2"
INTERMEDIATE_DIR="$3"

if [ -f /opt/oryx/logger ]; then
	source /opt/oryx/logger
fi

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Source directory '$SOURCE_DIR' does not exist." 1>&2
    exit 1
fi


cd "$SOURCE_DIR"
SOURCE_DIR=$(pwd -P)

if [ -z "$DESTINATION_DIR" ]
then
    DESTINATION_DIR="$SOURCE_DIR"
fi

if [ -d "$DESTINATION_DIR" ]
then
    cd "$DESTINATION_DIR"
    DESTINATION_DIR=$(pwd -P)
fi



if [ ! -z "$INTERMEDIATE_DIR" ]
then
	echo "Using intermediate directory '$INTERMEDIATE_DIR'."
	if [ ! -d "$INTERMEDIATE_DIR" ]
	then
		echo
		echo "Intermediate directory doesn't exist, creating it...'"
		mkdir -p "$INTERMEDIATE_DIR"		
	fi

	cd "$INTERMEDIATE_DIR"
	INTERMEDIATE_DIR=$(pwd -P)
	cd "$SOURCE_DIR"
	echo
	echo "Copying files to the intermediate directory..."
	START_TIME=$SECONDS
	excludedDirectories=""
	
		excludedDirectories+=" --exclude .git"
		

	
	rsync -rcE --delete $excludedDirectories . "$INTERMEDIATE_DIR"

	ELAPSED_TIME=$(($SECONDS - $START_TIME))
	echo "Done in $ELAPSED_TIME sec(s)."
	SOURCE_DIR="$INTERMEDIATE_DIR"
fi

echo
echo "Source directory     : $SOURCE_DIR"
echo "Destination directory: $DESTINATION_DIR"
echo



if grep -q cli "/opt/oryx/.imagetype"; then
echo 'Installing common platform dependencies...'
apt-get update
apt-get upgrade -y
apt-get install -y --no-install-recommends \
  git
rm -rf /var/lib/apt/lists/*
echo 'Installing php specific dependencies...'
if [[ "${DEBIAN_FLAVOR}" = "buster" || "${DEBIAN_FLAVOR}" = "bullseye" ]]; then
apt-get update
apt-get upgrade -y
apt-get install -y --no-install-recommends \
  ca-certificates libargon2-0 libcurl4-openssl-dev libedit-dev libonig-dev libncurses6 libsodium-dev libsqlite3-dev libxml2-dev xz-utils
rm -rf /var/lib/apt/lists/*
else
tmpDir="/opt/tmp"
imagesDir="$tmpDir/images"
$imagesDir/build/php/prereqs/installPrereqs.sh
apt-get update
apt-get upgrade -y
apt-get install -y --no-install-recommends \
  libcurl3 libicu57 liblttng-ust0 libssl1.0.2 libargon2-0 libonig-dev libncurses5-dev libxml2-dev libedit-dev
rm -rf /var/lib/apt/lists/*
fi
fi
PLATFORM_SETUP_START=$SECONDS
echo
echo "Downloading and extracting 'php' version '8.2.5' to '/tmp/oryx/platforms/php/8.2.5'..."
rm -rf /tmp/oryx/platforms/php/8.2.5
mkdir -p /tmp/oryx/platforms/php/8.2.5
cd /tmp/oryx/platforms/php/8.2.5
PLATFORM_BINARY_DOWNLOAD_START=$SECONDS
platformName="php"
export DEBIAN_FLAVOR=bullseye
echo "Detected image debian flavor: $DEBIAN_FLAVOR."
if [ "$DEBIAN_FLAVOR" == "stretch" ]; then
curl -D headers.txt -SL "https://oryx-cdn.microsoft.io/php/php-8.2.5.tar.gz" --output 8.2.5.tar.gz >/dev/null 2>&1
else
curl -D headers.txt -SL "https://oryx-cdn.microsoft.io/php/php-$DEBIAN_FLAVOR-8.2.5.tar.gz$ORYX_SDK_STORAGE_ACCOUNT_ACCESS_TOKEN" --output 8.2.5.tar.gz >/dev/null 2>&1
fi
PLATFORM_BINARY_DOWNLOAD_ELAPSED_TIME=$(($SECONDS - $PLATFORM_BINARY_DOWNLOAD_START))
echo "Downloaded in $PLATFORM_BINARY_DOWNLOAD_ELAPSED_TIME sec(s)."
echo Verifying checksum...
headerName="x-ms-meta-checksum"
checksumHeader=$(cat headers.txt | grep -i $headerName: | tr -d '\r')
checksumHeader=$(echo $checksumHeader | tr '[A-Z]' '[a-z]')
checksumValue=${checksumHeader#"$headerName: "}
rm -f headers.txt
echo Extracting contents...
tar -xzf 8.2.5.tar.gz -C .
if [ "$platformName" = "golang" ]; then
echo "performing sha256sum for : php..."
echo "$checksumValue 8.2.5.tar.gz" | sha256sum -c - >/dev/null 2>&1
else
echo "performing sha512 checksum for: php..."
echo "$checksumValue 8.2.5.tar.gz" | sha512sum -c - >/dev/null 2>&1
fi
rm -f 8.2.5.tar.gz
PLATFORM_SETUP_ELAPSED_TIME=$(($SECONDS - $PLATFORM_SETUP_START))
echo "Done in $PLATFORM_SETUP_ELAPSED_TIME sec(s)."
echo
oryxImageDetectorFile="/opt/oryx/.imagetype"
oryxOsDetectorFile="/opt/oryx/.ostype"
if [ -f "$oryxImageDetectorFile" ] && [ "$platformName" = "dotnet" ] && grep -q "jamstack" "$oryxImageDetectorFile"; then
echo "image detector file exists, platform is dotnet.."
PATH=/opt/dotnet/8.2.5/dotnet:$PATH
fi
if [ -f "$oryxImageDetectorFile" ] && [ "$platformName" = "dotnet" ] && grep -q "vso-" "$oryxImageDetectorFile"; then
echo "image detector file exists, platform is dotnet.."
source /opt/tmp/build/createSymlinksForDotnet.sh
fi
if [ -f "$oryxImageDetectorFile" ] && [ "$platformName" = "nodejs" ] && grep -q "vso-" "$oryxImageDetectorFile"; then
echo "image detector file exists, platform is nodejs.."
mkdir -p /home/codespace/nvm
ln -sfn /opt/nodejs/8.2.5 /home/codespace/nvm/current
fi
if [ -f "$oryxImageDetectorFile" ] && [ "$platformName" = "php" ] && grep -q "vso-" "$oryxImageDetectorFile"; then
echo "image detector file exists, platform is php.."
mkdir -p /home/codespace/.php
ln -sfn /opt/php/8.2.5 /home/codespace/.php/current
fi
if [ -f "$oryxImageDetectorFile" ] && [ "$platformName" = "python" ] && grep -q "vso-" "$oryxImageDetectorFile"; then
   echo "image detector file exists, platform is python.."
  [ -d "/opt/python/$VERSION" ] && echo /opt/python/8.2.5/lib >> /etc/ld.so.conf.d/python.conf
  ldconfig
  mkdir -p /home/codespace/.python
  ln -sfn /opt/python/8.2.5 /home/codespace/.python/current
fi
if [ -f "$oryxImageDetectorFile" ] && [ "$platformName" = "java" ] && grep -q "vso-" "$oryxImageDetectorFile"; then
echo "image detector file exists, platform is java.."
mkdir -p /home/codespace/java
ln -sfn /opt/java/8.2.5 /home/codespace/java/current
fi
if [ -f "$oryxImageDetectorFile" ] && [ "$platformName" = "ruby" ] && grep -q "vso-" "$oryxImageDetectorFile"; then
echo "image detector file exists, platform is ruby.."
mkdir -p /home/codespace/.ruby
ln -sfn /opt/ruby/8.2.5 /home/codespace/.ruby/current
fi
if [ -f "$oryxImageDetectorFile" ] && [ -f "$oryxOsDetectorFile" ] && [ "$platformName" = "python" ] && grep -q "githubactions" "$oryxImageDetectorFile" && grep -q "BULLSEYE" "$oryxOsDetectorFile"; then
  echo "image detector file exists, platform is python.."
  echo "OS detector file exists, OS is bullseye.."
  if [ '8.2.5' == 3.7* ] || [ '8.2.5' == 3.8* ]; then
    curl -LO http://ftp.de.debian.org/debian/pool/main/libf/libffi/libffi6_3.2.1-9_amd64.deb
    dpkg -i libffi6_3.2.1-9_amd64.deb
    rm libffi6_3.2.1-9_amd64.deb
  fi
fi
echo > /tmp/oryx/platforms/php/8.2.5/.oryx-sdkdownload-sentinel


if grep -q cli "/opt/oryx/.imagetype"; then
echo 'Installing common platform dependencies...'
apt-get update
apt-get upgrade -y
apt-get install -y --no-install-recommends \
  git
rm -rf /var/lib/apt/lists/*
echo 'Installing php-composer specific dependencies...'
if [[ "${DEBIAN_FLAVOR}" = "buster" || "${DEBIAN_FLAVOR}" = "bullseye" ]]; then
apt-get update
apt-get upgrade -y
apt-get install -y --no-install-recommends \
  ca-certificates libargon2-0 libcurl4-openssl-dev libedit-dev libonig-dev libncurses6 libsodium-dev libsqlite3-dev libxml2-dev xz-utils
rm -rf /var/lib/apt/lists/*
else
tmpDir="/opt/tmp"
imagesDir="$tmpDir/images"
$imagesDir/build/php/prereqs/installPrereqs.sh
apt-get update
apt-get upgrade -y
apt-get install -y --no-install-recommends \
  libcurl3 libicu57 liblttng-ust0 libssl1.0.2 libargon2-0 libonig-dev libncurses5-dev libxml2-dev libedit-dev
rm -rf /var/lib/apt/lists/*
fi
fi
PLATFORM_SETUP_START=$SECONDS
echo
echo "Downloading and extracting 'php-composer' version '2.3.4' to '/tmp/oryx/platforms/php-composer/2.3.4'..."
rm -rf /tmp/oryx/platforms/php-composer/2.3.4
mkdir -p /tmp/oryx/platforms/php-composer/2.3.4
cd /tmp/oryx/platforms/php-composer/2.3.4
PLATFORM_BINARY_DOWNLOAD_START=$SECONDS
platformName="php-composer"
export DEBIAN_FLAVOR=bullseye
echo "Detected image debian flavor: $DEBIAN_FLAVOR."
if [ "$DEBIAN_FLAVOR" == "stretch" ]; then
curl -D headers.txt -SL "https://oryx-cdn.microsoft.io/php-composer/php-composer-2.3.4.tar.gz" --output 2.3.4.tar.gz >/dev/null 2>&1
else
curl -D headers.txt -SL "https://oryx-cdn.microsoft.io/php-composer/php-composer-$DEBIAN_FLAVOR-2.3.4.tar.gz$ORYX_SDK_STORAGE_ACCOUNT_ACCESS_TOKEN" --output 2.3.4.tar.gz >/dev/null 2>&1
fi
PLATFORM_BINARY_DOWNLOAD_ELAPSED_TIME=$(($SECONDS - $PLATFORM_BINARY_DOWNLOAD_START))
echo "Downloaded in $PLATFORM_BINARY_DOWNLOAD_ELAPSED_TIME sec(s)."
echo Verifying checksum...
headerName="x-ms-meta-checksum"
checksumHeader=$(cat headers.txt | grep -i $headerName: | tr -d '\r')
checksumHeader=$(echo $checksumHeader | tr '[A-Z]' '[a-z]')
checksumValue=${checksumHeader#"$headerName: "}
rm -f headers.txt
echo Extracting contents...
tar -xzf 2.3.4.tar.gz -C .
if [ "$platformName" = "golang" ]; then
echo "performing sha256sum for : php-composer..."
echo "$checksumValue 2.3.4.tar.gz" | sha256sum -c - >/dev/null 2>&1
else
echo "performing sha512 checksum for: php-composer..."
echo "$checksumValue 2.3.4.tar.gz" | sha512sum -c - >/dev/null 2>&1
fi
rm -f 2.3.4.tar.gz
PLATFORM_SETUP_ELAPSED_TIME=$(($SECONDS - $PLATFORM_SETUP_START))
echo "Done in $PLATFORM_SETUP_ELAPSED_TIME sec(s)."
echo
oryxImageDetectorFile="/opt/oryx/.imagetype"
oryxOsDetectorFile="/opt/oryx/.ostype"
if [ -f "$oryxImageDetectorFile" ] && [ "$platformName" = "dotnet" ] && grep -q "jamstack" "$oryxImageDetectorFile"; then
echo "image detector file exists, platform is dotnet.."
PATH=/opt/dotnet/2.3.4/dotnet:$PATH
fi
if [ -f "$oryxImageDetectorFile" ] && [ "$platformName" = "dotnet" ] && grep -q "vso-" "$oryxImageDetectorFile"; then
echo "image detector file exists, platform is dotnet.."
source /opt/tmp/build/createSymlinksForDotnet.sh
fi
if [ -f "$oryxImageDetectorFile" ] && [ "$platformName" = "nodejs" ] && grep -q "vso-" "$oryxImageDetectorFile"; then
echo "image detector file exists, platform is nodejs.."
mkdir -p /home/codespace/nvm
ln -sfn /opt/nodejs/2.3.4 /home/codespace/nvm/current
fi
if [ -f "$oryxImageDetectorFile" ] && [ "$platformName" = "php" ] && grep -q "vso-" "$oryxImageDetectorFile"; then
echo "image detector file exists, platform is php.."
mkdir -p /home/codespace/.php
ln -sfn /opt/php/2.3.4 /home/codespace/.php/current
fi
if [ -f "$oryxImageDetectorFile" ] && [ "$platformName" = "python" ] && grep -q "vso-" "$oryxImageDetectorFile"; then
   echo "image detector file exists, platform is python.."
  [ -d "/opt/python/$VERSION" ] && echo /opt/python/2.3.4/lib >> /etc/ld.so.conf.d/python.conf
  ldconfig
  mkdir -p /home/codespace/.python
  ln -sfn /opt/python/2.3.4 /home/codespace/.python/current
fi
if [ -f "$oryxImageDetectorFile" ] && [ "$platformName" = "java" ] && grep -q "vso-" "$oryxImageDetectorFile"; then
echo "image detector file exists, platform is java.."
mkdir -p /home/codespace/java
ln -sfn /opt/java/2.3.4 /home/codespace/java/current
fi
if [ -f "$oryxImageDetectorFile" ] && [ "$platformName" = "ruby" ] && grep -q "vso-" "$oryxImageDetectorFile"; then
echo "image detector file exists, platform is ruby.."
mkdir -p /home/codespace/.ruby
ln -sfn /opt/ruby/2.3.4 /home/codespace/.ruby/current
fi
if [ -f "$oryxImageDetectorFile" ] && [ -f "$oryxOsDetectorFile" ] && [ "$platformName" = "python" ] && grep -q "githubactions" "$oryxImageDetectorFile" && grep -q "BULLSEYE" "$oryxOsDetectorFile"; then
  echo "image detector file exists, platform is python.."
  echo "OS detector file exists, OS is bullseye.."
  if [ '2.3.4' == 3.7* ] || [ '2.3.4' == 3.8* ]; then
    curl -LO http://ftp.de.debian.org/debian/pool/main/libf/libffi/libffi6_3.2.1-9_amd64.deb
    dpkg -i libffi6_3.2.1-9_amd64.deb
    rm libffi6_3.2.1-9_amd64.deb
  fi
fi
echo > /tmp/oryx/platforms/php-composer/2.3.4/.oryx-sdkdownload-sentinel






cd "$SOURCE_DIR"


if [ -f /opt/oryx/benv ]; then
	source /opt/oryx/benv php=8.2.5 composer=2.3.4 dynamic_install_root_dir="/tmp/oryx/platforms"
fi





export SOURCE_DIR
export DESTINATION_DIR


mkdir -p "$DESTINATION_DIR"



cd "$SOURCE_DIR"
echo "Executing pre-build command..."
"/home/site/repository/deployment/core/recipes/azure.linux/hooks/prebuild.sh"
echo "Finished executing pre-build command."




cd "$SOURCE_DIR"
phpBin=`which php`
echo "PHP executable: $phpBin"


echo "Composer archive: $composer"
echo "Running 'composer install --ignore-platform-reqs --no-interaction'..."
echo
# `--ignore-platform-reqs` ensures Composer won't fail a build when
# an extension is missing from the build image (it could exist in the
# runtime image regardless)
php $composer install --ignore-platform-reqs --no-interaction






cd $SOURCE_DIR
echo
echo "Executing post-build command..."
"/home/site/repository/deployment/core/recipes/azure.linux/hooks/postbuild.sh"
echo "Finished executing post-build command."


if [ "$SOURCE_DIR" != "$DESTINATION_DIR" ]
then
	echo "Preparing output..."

	
	

		
			cd "$SOURCE_DIR"
	
			echo
			echo "Copying files to destination directory '$DESTINATION_DIR'..."
			START_TIME=$SECONDS
			excludedDirectories=""
			
				excludedDirectories+=" --exclude .git"
				
	
			
	
			
			rsync -rcE --links $excludedDirectories . "$DESTINATION_DIR"
	
			
	
			ELAPSED_TIME=$(($SECONDS - $START_TIME))
			echo "Done in $ELAPSED_TIME sec(s)."
		

	
fi


MANIFEST_FILE=oryx-manifest.toml

MANIFEST_DIR=
if [ -z "$MANIFEST_DIR" ];then
	MANIFEST_DIR="$DESTINATION_DIR"
fi
mkdir -p "$MANIFEST_DIR"

echo
echo "Removing existing manifest file"
rm -f "$MANIFEST_DIR/$MANIFEST_FILE"

echo "Creating a manifest file..."

echo "PhpVersion=\"8.2.5\"" >> "$MANIFEST_DIR/$MANIFEST_FILE"

echo "OperationId=\"21266f6a7ec671de\"" >> "$MANIFEST_DIR/$MANIFEST_FILE"

echo "SourceDirectoryInBuildContainer=\"/tmp/8db61c2d5e3e526\"" >> "$MANIFEST_DIR/$MANIFEST_FILE"

echo "PlatformName=\"php\"" >> "$MANIFEST_DIR/$MANIFEST_FILE"

echo "CompressDestinationDir=\"false\"" >> "$MANIFEST_DIR/$MANIFEST_FILE"

echo "Manifest file created."



OS_TYPE_SOURCE_DIR="/opt/oryx/.ostype"
if [ -f "$OS_TYPE_SOURCE_DIR" ]
then
	echo "Copying .ostype to manifest output directory."
	cp "$OS_TYPE_SOURCE_DIR" "$MANIFEST_DIR/.ostype"
else
	echo "File $OS_TYPE_SOURCE_DIR does not exist. Cannot copy to manifest directory." 1>&2
	exit 1
fi

TOTAL_EXECUTION_ELAPSED_TIME=$(($SECONDS - $TOTAL_EXECUTION_START_TIME))
echo
echo "Done in $TOTAL_EXECUTION_ELAPSED_TIME sec(s)."