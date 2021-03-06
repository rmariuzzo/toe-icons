#! /bin/bash

PACKAGE_VERSION=`node -p -e "require('./package.json').version"`

HAS_CHANGES=`git diff | wc -l`

if [ $HAS_CHANGES -ne 0 ]; then
  echo "Working directory not clean, please commit all pending files"
  exit 1
fi

if [[ -z $1 ]]; then
  echo "Enter new version (currently $PACKAGE_VERSION): "
  read VERSION
else
  VERSION=$1
fi

if [ $VERSION = $PACKAGE_VERSION ]; then
  echo "No version change, exiting"
  exit 1
fi

read -p "Releasing $VERSION - are you sure? (y/N) " continue

if [[ $continue =~ ^[Nn]$ ]]; then
  echo "Cancelled"
  exit 1
fi

echo
echo "* * * * * * * Releasing $VERSION * * * * * * *"
echo

# update package.json version to be used in the build
npm version $VERSION --no-git-tag-version

# build
echo "Building..."
npm run build

# generate the git tag
echo "Tagging..."
git tag v$VERSION

# commit
git add -A
git commit -m "[build] $VERSION"

# publish
echo "Pushing..."
git push origin refs/tags/v$VERSION
git push

echo "Publishing to NPM..."
sed 's#"main": "./dist/components.js",#"main": "./components.js",#' package.json > ./dist/package.json

cd ./dist
npm publish

# update the docs
echo "Updating the docs..."
cd ..
npm run docs

echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
echo "* All done!, now remember to add the release information on the github repo:  *"
echo "*           https://github.com/javisperez/toe-icons/releases                  *"
echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
