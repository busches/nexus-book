#!/bin/bash

# assemble.sh processes the output files created by build.sh and prepares
# the folders target/site and target/archive for rsync runs to
# staging and production

# see build.sh
# see deploy-to-prodcution.sh
# see deploy-to-staging.sh
# see deploy-locally.sh

# fail if anything errors
set -e
# fail if a function call is missing an argument
set -u

dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
echo "Processing in ${dir}"

templateScript=../nexus-documentation-wrapper/apply-template.sh
docProperties=$dir/nexus-book.properties
source $docProperties

echo "Nexus Repository Manager Version $version"

if [ $publish_master == "true" ]; then
    echo "Preparing for master deployment"
    rm -rf target/site/reference3
    rm -rf target/site/pdf3
    rm -rf target/site/other3
    mkdir -p target/site/reference3
    mkdir -p target/site/pdf3
    mkdir -p target/site/other3
fi

echo "Preparing for version $version deployment"
rm -rf target/site/$version/reference
rm -rf target/site/$version/pdf
rm -rf target/site/$version/other
mkdir -p target/site/$version/reference
mkdir -p target/site/$version/pdf
mkdir -p target/site/$version/other

if [ $publish_master == "true" ]; then
    echo "Copying for master deployment"
    cp -r target/book-nexus.chunked/*  target/site/reference3
    cp target/book-nexus.pdf target/site/pdf3/nxbook-pdf.pdf
    cp target/sonatype-nexus-eval-guide.pdf target/site/pdf3/sonatype-nexus-eval-guide.pdf
    cp target/book-nexus.epub target/site/other3/nexus-book.epub
fi

echo "Copying for version $version deployment"

# NOT copying the overall index into version specific directories since links would be broken and 
# it is an overall index
cp -r target/book-nexus.chunked/* target/site/$version/reference
cp target/book-nexus.pdf target/site/$version/pdf/nxbook-pdf.pdf
cp target/sonatype-nexus-eval-guide.pdf target/site/$version/pdf/sonatype-nexus-eval-guide.pdf
cp target/book-nexus.epub target/site/$version/other/nexus-book.epub
echo "Copying redirector"
cp -v site/global/index.html target/site/$version/


if [ $publish_master == "true" ]; then
echo "Invoking templating process for master"
$templateScript $dir/target/site/reference3 $docProperties "block" "../../" "book"
fi

echo "Invoking templating process for $version "
$templateScript $dir/target/site/$version/reference $docProperties "block" "../../../" "book"

if [ $publish_index == "true" ]; then
  echo "Preparing Nexus Repository and Nexus Documentation index for deployment"
  rm -rf target/site/nexus-documentation
  mkdir -p target/site/nexus-documentation

  echo "  Copying content and resources"
  cp target/index.html target/site
  echo "Invoking templating for index page"
  $templateScript $dir/target/site/ $docProperties "none" "../" "article"
  cp -rv site/global/sitemap*.xml target/site
  echo "... done"

  echo "Preparing Nexus Documentation index for deployment"
  cp target/nexus-documentation.html target/site/nexus-documentation/index.html
  echo "Invoking templating for index page"
  $templateScript $dir/target/site/nexus-documentation/ "nexus-documentation.properties" "none" "" "article"
  echo "... done"
fi
