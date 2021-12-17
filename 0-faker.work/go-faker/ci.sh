#!/usr/bin/env bash

APPNAME=faker
VERSION=0.2.5

function ci-entry() {
  if [ $# -eq 0 ]; then
    echo "Usage: $0 [deb|dmg] ..."
  else
    local cmd=$1 && shift
    ci-$cmd "$@"
  fi
}

ci-dmg() {
  sudo apt install -y hfsprogs

  local ARCH=amd64
  local DMG_NAME=$APPNAME-$VERSION.dmg
  local VOL_NAME=$APPNAME-$VERSION-Install
  dd if=/dev/zero of=/tmp/$DMG_NAME bs=1M count=16 status=progress
  mkfs.hfsplus -v $VOL_NAME /tmp/$DMG_NAME
  ls -la --color /tmp/$DMG_NAME

  local MNT_POINT=/mnt/tmp
  sudo mkdir -pv $MNT_POINT/conf.d
  sudo mount -o loop /tmp/$DMG_NAME $MNT_POINT
  sudo cp -av ./bin/${APPNAME}_darwin-$ARCH $MNT_POINT/$APPNAME
  sudo cp -avR ./ci/etc/$APPNAME/* $MNT_POINT/
  ls -la --color $MNT_POINT/
  sudo umount $MNT_POINT
}

ci-deb() {
  local WORK_DIR="$PWD/.tmp"
  local ARCH=amd64

  local DEB_NAME="$APPNAME-$VERSION"
  local SRC_TREE="$WORK_DIR/$DEB_NAME"
  local TGT="$SRC_TREE/usr/lib/$APPNAME"
  #  local ETC="$SRC_TREE/etc"
  #  local MAN="$SRC_TREE/usr/share/man/man1"
  #local DEBIAN="$SRC_TREE/debian"  # for dpkg-buildpackage, or debuild
  local DEBIAN="$SRC_TREE/DEBIAN"  # for dpkg-deb --build

  local clean="$DEBIAN/$APPNAME.clean"
  local links="$DEBIAN/$APPNAME.links"
  local manpages="$DEBIAN/manpages"
  local bashcomp="$DEBIAN/$APPNAME.bash-completion"

  sudo apt install -y debmake

  [ -d $WORK_DIR ] && rm -rf $WORK_DIR
  mkdir -pv \
      $SRC_TREE \
      $DEBIAN \
      $TGT/{etc,man,completions} \
      $TGT/completions/{zsh,bash}
  #    $TGT/share/doc/$APPNAME
  cp ./ci/deb/debian/* $DEBIAN/

  # touch $links $manpages $bashcomp $clean $DEBIAN/install && \
  touch $clean && chmod +x $clean

  cp ./bin/${APPNAME}_linux-$ARCH $TGT/$APPNAME \
    && echo # "$APPNAME    usr/bin" >>$DEBIAN/install

  cp -avR ./ci/etc/$APPNAME $TGT/etc/ \
    && echo # "/usr/lib/$APPNAME/etc/$APPNAME    /etc/$APPNAME" >>$links
  [ -d ./ci/certs ] && cp -avR ./ci/certs $TGT/etc/$APPNAME/

  $TGT/$APPNAME gen sh --bash -d $TGT/completions/bash/ > $TGT/completions/bash/$APPNAME \
    && echo #"/usr/lib/$APPNAME/completions/bash/$APPNAME" >>$bashcomp
  $TGT/$APPNAME gen sh --zsh -d $TGT/completions/zsh/ > $TGT/completions/zsh/_$APPNAME \
    && echo #"/usr/lib/$APPNAME/completions/zsh/_$APPNAME /usr/local/share/zsh/site-functions/_$APPNAME" >>$links

  #    && gzip -f -q $TGT/man/man1/*.1 \
  $TGT/$APPNAME gen man -d $TGT/man/man1/ \
    && for f in $TGT/man/man1/*.1; do
      local fn=$(basename $f)
      # echo "man/man1/$fn" >>$manpages
      gzip $f
    done

  cd $WORK_DIR && dpkg-deb --build $DEB_NAME && cd ..
  # using a build system
  # cd $SRC_TREE && ls -la --color && sudo dpkg-buildpackage -a amd64 -us -uc -b && cd ../..

  #[ -d $DEBIAN/$APPNAME ] || mkdir $DEBIAN/$APPNAME
  #ln -s $SRC_TREE/usr $DEBIAN/$APPNAME/
  #cd $SRC_TREE && ls -la --color && sudo debuild -a amd64 -us -uc -ui -i -i -b && cd ../..
}

ci-entry "$@"