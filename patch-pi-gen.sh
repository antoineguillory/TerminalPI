#! bin/sh

git init
unzip files/pi-gen.zip >> logs.txt

cd pi-gen/

# Création du fichier config
echo -n "\n\nVeuillez choisir un nom pour votre distribution : "
read IMG_NAME
echo "IMG_NAME='$IMG_NAME'" > config

read -p "Entrez l'adresse IP du server : " IP_SERVER

# Enlève les stages inutiles
touch ./stage3/SKIP ./stage4/SKIP ./stage5/SKIP
touch ./stage4/SKIP_IMAGES ./stage5/SKIP_IMAGES

# Supprime la génération de la distro NOOBS
rm ./stage2/EXPORT_NOOBS

# Ajoute une étape de génération dans le stage2
mkdir ./stage2/03-extra
echo "lightdm" > ./stage2/03-extra/00-packages

mkdir ./stage2/03-extra/files
cp ../files/lightdm.conf ./stage2/03-extra/files/
sed "s/\(X -query \).*$/\1$IP_SERVER/" ../files/Xstart > ./stage2/03-extra/files/Xstart

# Génération du fichier 01-run.sh qui installe nos fichiers de configuration
echo "#!/bin/bash -e" > ./stage2/03-extra/01-run.sh
echo 'install -v -d					"${ROOTFS_DIR}/etc/lightdm"' >> ./stage2/03-extra/01-run.sh
echo 'install -v -m 644 ./files/lightdm.conf ${ROOTFS_DIR}/etc/lightdm/' >> ./stage2/03-extra/01-run.sh
echo 'install -v -d					"${ROOTFS_DIR}/etc/init.d"' >> ./stage2/03-extra/01-run.sh
echo 'install -v -m 755 ./files/Xstart ${ROOTFS_DIR}/etc/init.d/' >> ./stage2/03-extra/01-run.sh
echo "on_chroot << EOF" >> ./stage2/03-extra/01-run.sh
echo "update-rc.d Xstart defaults" >> ./stage2/03-extra/01-run.sh
echo "EOF" >> ./stage2/03-extra/01-run.sh
chmod 755 ./stage2/03-extra/01-run.sh

# Patch du fichier export-image/prerun.sh
cp ../files/export-image.patch export-image/
cd export-image
patch < export-image.patch
cd ..

# On installe les dépendances de pi-gen
echo -n "\n\nEntrez le mot de passe sudo pour installer les dépendances : "
# read -s password # lecture sans retour
read password
sudo --prompt=$password apt-get update
sudo --prompt=$password apt-get install quilt parted realpath \
 qemu-user-static debootstrap zerofree pxz zip dosfstools bsdtar libcap2-bin \
 grep rsync xz-utils
