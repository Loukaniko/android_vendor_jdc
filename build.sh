#! /bin/bash

# ___    __    __  __  ___    __    ___  ____  ___ 
#/ __)  /__\  (  )(  )/ __)  /__\  / __)( ___)/ __)
#\__ \ /(__)\  )(__)( \__ \ /(__)\( (_-. )__) \__ \
#(___/(__)(__)(______)(___/(__)(__)\___/(____)(___/
#
# Copyright 2018 JDCTeam,BBQ team
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


TEAM_NAME="Barbeque"
TARGET=jflte
VARIANT=userdebug
CM_VER=15.1
OUT="out/target/product/jflte"
FILENAME=Sausages-"$CM_VER"-"$(date +%Y%m%d)"-"$TARGET"

buildROM()
{
	echo "Building..."
	time schedtool -B -n 1 -e ionice -n 1 make otapackage -j"$CPU_NUM" "$@"
	if [ "$?" == 0 ]; then
		echo "Build done"
	else
		echo "Build failed"
	fi
	croot
}

anythingElse() {
    echo " "
    echo " "
    echo "Anything else?"
    select more in "Yes" "No"; do
        case $more in
            Yes ) bash build.sh; break;;
            No ) exit 0; break;;
        esac
    done ;
}

deepClean() {
	ccache -C
	ccache -c
	echo "Making clean"
	make clean
	echo "Making clobber"
	make clobber

}

getBuild() {
	croot
	rm -rf build
	repo sync build/make
	repo sync build/kati
	repo sync build/soong
	repo sync build/blueprint
	
	
	echo -e "\e[1;91m==============================================================="
	echo -e "\e[0m "
	echo -e "\e[1;91mPlease update your device tree,aroma,Substratum"
	echo ""
	echo "==============================================================="
	echo -e "\e[0m "
}

upstreamMerge() {

	croot
	echo "Refreshing manifest"
	repo init -u git://github.com/loukaniko/platform_manifests.git -b 8.1
	echo "Syncing projects"
	repo sync --force-sync
	echo "Getting prebuilts"
	cd vendor/jdc
	./get-prebuilts
	croot
        echo "Upstream merging"
        ## Our snippet/manifest
        ROOMSER=.repo/manifests/snippets/sausages.xml
        # Lines to loop over
        CHECK=$(cat ${ROOMSER} | grep -e "<remove-project" | cut -d= -f3 | sed 's/revision//1' | sed 's/\"//g' | sed 's|/>||g')

        ## Upstream merging for forked repos
        while read -r line; do
            echo "Upstream merging for $line"
	    rm -rf $line
	    repo sync $line
	    cd "$line"
	    git branch -D opt-cm-15.1
	    git checkout -b opt-cm-15.1
            UPSTREAM=$(sed -n '1p' UPSTREAM)
            BRANCH=$(sed -n '2p' UPSTREAM)

            git pull https://www.github.com/"$UPSTREAM" "$BRANCH"
            git push origin 8.1
            croot
        done <<< "$CHECK"

}


echo " "
echo -e "\e[1;91mWelcome to the $TEAM_NAME build script"
echo -e "\e[0m "
echo "Setting up build environment..."
. build/envsetup.sh > /dev/null
echo "Setting build target $TARGET""..."
lunch aicp_"$TARGET"-"$VARIANT" > /dev/null
echo " "
echo -e "\e[1;91mPlease make your selections carefully"
echo -e "\e[0m "
echo " "
select build in "Refresh manifest,repo sync and upstream merge" "Build ROM" "Refresh build directory" "Deep clean(inc. ccache)" "Exit"; do
	case $build in
		"Refresh manifest,repo sync and upstream merge" ) upstreamMerge; getBuild;anythingElse; break;;
		"Build ROM" ) buildROM; anythingElse; break;;
		"Refresh build directory" ) getBuild; anythingElse; break;;
		"Deep clean(inc. ccache)" ) aluclean=true; deepClean; anythingElse; break;;
		"Exit" ) exit 0; break;;
	esac
done
exit 0
