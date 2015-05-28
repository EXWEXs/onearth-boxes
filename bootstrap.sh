#!/usr/bin/env bash

#Projections and their EPSG equivalents
declare -a PROJECTIONS=(geo webmerc arctic antarctic)
declare -a PROJEPSGS=(EPSG4326 EPSG3857 EPSG3413 EPSG3031)

#Install Apache
sudo yum install -y httpd

#Download and install OnEarth and required packages
sudo yum -y install epel-release
curl -# -L https://github.com/nasa-gibs/onearth/releases/download/v0.6.3/onearth-0.6.3.tar.gz | tar xvz
sudo yum -y install gibs-gdal-*
sudo yum -y install onearth-*

#sudo ldconfig -v

#Set LCDIR
echo "export LCDIR=/etc/onearth/config" >> .bashrc
source ~/.bashrc

#Modify sudoers file to keep LCDIR in the sudo envvars
sudo sed -i 's/.*LC_TIME LC_ALL LANGUAGE LINGUAS _XKB_CHARSET XAUTHORITY.*/&\nDefaults    env_keep += \"LCDIR\"/' /etc/sudoers

#Replace OnEarth Apache config file with the one that's included in this package
sudo cp /vagrant/on_earth-demo.conf /etc/httpd/conf.d/on_earth-demo.conf

#Set up WTMS/TWMS OpenLayers demo endpoints for all 4 projections we're using
sudo mkdir -p /usr/share/onearth/demo/lib
sudo cp -R /vagrant/endpoint_configs/html_lib/* /usr/share/onearth/demo/lib/
for PROJECTION in "${PROJECTIONS[@]}"
do
	sudo mkdir /usr/share/onearth/demo/wmts-$PROJECTION/
	sudo cp /usr/share/onearth/apache/{wmts.cgi,black.jpg,transparent.png} /usr/share/onearth/demo/wmts-$PROJECTION/
	sudo cp /vagrant/endpoint_configs/wmts-$PROJECTION/{*.js,*.html} /usr/share/onearth/demo/wmts-$PROJECTION/
	sudo mkdir -p /usr/share/onearth/demo/twms-$PROJECTION/.lib
	sudo cp -R /usr/share/onearth/apache/ /usr/share/onearth/demo/twms-$PROJECTION/
done

#Create MRF directories and copy source/empty tile images and config XML files, then create MRF, copy images to archive, copy MRF to header dir
#and copy layer config

#Blue marble - geographic and webmercator (using same source image)
declare -a MARBLE_PROJECTIONS=(geo webmerc)
for INDEX in {0..1}
do 
	#Copy image files and set up MRF process dirs
	mkdir -p /vagrant/generated_mrfs/blue_marble2004336_${MARBLE_PROJECTIONS[$INDEX]}/{source_images,working_dir,logfile_dir,output_dir,empty_tiles}
	cp /vagrant/source_images/blue_marble2004336.* /vagrant/generated_mrfs/blue_marble2004336_${MARBLE_PROJECTIONS[$INDEX]}/source_images/
	cp /vagrant/mrf_configs/blue_marble2004336_${MARBLE_PROJECTIONS[$INDEX]}_config.xml /vagrant/generated_mrfs/blue_marble2004336_${MARBLE_PROJECTIONS[$INDEX]}/
	cp /usr/share/onearth/apache/black.jpg /vagrant/generated_mrfs/blue_marble2004336_${MARBLE_PROJECTIONS[$INDEX]}/empty_tiles/
	cd /vagrant/generated_mrfs/blue_marble2004336_${MARBLE_PROJECTIONS[$INDEX]}/

	mrfgen -c /vagrant/generated_mrfs/blue_marble2004336_${MARBLE_PROJECTIONS[$INDEX]}/blue_marble2004336_${MARBLE_PROJECTIONS[$INDEX]}_config.xml

	#Create data archive directories and copy MRF files
	sudo mkdir -p /usr/share/onearth/demo/data/${PROJEPSGS[$INDEX]}/blue_marble2004336/
	sudo cp /vagrant/generated_mrfs/blue_marble2004336_${MARBLE_PROJECTIONS[$INDEX]}/output_dir/blue_marble2004336_.* /usr/share/onearth/demo/data/${PROJEPSGS[$INDEX]}/blue_marble2004336/
	sudo cp /vagrant/generated_mrfs/blue_marble2004336_${MARBLE_PROJECTIONS[$INDEX]}/output_dir/blue_marble2004336_.mrf /etc/onearth/config/headers/blue_marble2004336_${MARBLE_PROJECTIONS[$INDEX]}.mrf
done

#MODIS data 
declare -a MODIS_PROJECTIONS=(geo webmerc)
for INDEX in {0..0}
do
	#Copy image files and set up MRF process dirs
	mkdir -p /vagrant/generated_mrfs/MYR4ODLOLLDY_global_2014277_10km_${MODIS_PROJECTIONS[$INDEX]}/{source_images,working_dir,logfile_dir,output_dir,empty_tiles}
	cp /vagrant/source_images/MYR4ODLOLLDY_global_2014277_10km.* /vagrant/generated_mrfs/MYR4ODLOLLDY_global_2014277_10km_${MODIS_PROJECTIONS[$INDEX]}/source_images/
	cp /vagrant/mrf_configs/MYR4ODLOLLDY_global_2014277_10km_${MODIS_PROJECTIONS[$INDEX]}_config.xml /vagrant/generated_mrfs/MYR4ODLOLLDY_global_2014277_10km_${MODIS_PROJECTIONS[$INDEX]}/
	cp /usr/share/onearth/apache/transparent.png /vagrant/generated_mrfs/MYR4ODLOLLDY_global_2014277_10km_${MODIS_PROJECTIONS[$INDEX]}/empty_tiles/
	cd /vagrant/generated_mrfs/MYR4ODLOLLDY_global_2014277_10km_${MODIS_PROJECTIONS[$INDEX]}/

	mrfgen -c /vagrant/generated_mrfs/MYR4ODLOLLDY_global_2014277_10km_${MODIS_PROJECTIONS[$INDEX]}/MYR4ODLOLLDY_global_2014277_10km_${MODIS_PROJECTIONS[$INDEX]}_config.xml
 
	#Create data archive directories and copy MRF files
	sudo mkdir -p /usr/share/onearth/demo/data/${PROJEPSGS[$INDEX]}/MYR4ODLOLLDY_global_10km/{2014,YYYY}
	sudo cp /vagrant/generated_mrfs/MYR4ODLOLLDY_global_2014277_10km_${MODIS_PROJECTIONS[$INDEX]}/output_dir/MYR4ODLOLLDY2014277_.* /usr/share/onearth/demo/data/${PROJEPSGS[$INDEX]}/MYR4ODLOLLDY_global_10km/2014/
	sudo find /usr/share/onearth/demo/data/EPSG4326/MYR4ODLOLLDY_global_10km/2014 -name 'MYR4ODLOLLDY2014277*' -type f -exec bash -c 'ln -s "$1" "${1/2014277/TTTTTTT}"' -- {} \;
	sudo find /usr/share/onearth/demo/data/EPSG4326/MYR4ODLOLLDY_global_10km/2014 -name 'MYR4ODLOLLDYTTTTTTT*' -type l -exec bash -c 'mv "$1" "/usr/share/onearth/demo/data/EPSG4326/MYR4ODLOLLDY_global_10km/YYYY/"' -- {} \;
	sudo cp /vagrant/generated_mrfs/MYR4ODLOLLDY_global_2014277_10km_${MODIS_PROJECTIONS[$INDEX]}/output_dir/MYR4ODLOLLDY2014277_.mrf /etc/onearth/config/headers/MYR4ODLOLLDY_${MODIS_PROJECTIONS[$INDEX]}.mrf
done

#Set up and copy the pre-made MRFs
declare -a MRF_PROJS=(arctic antarctic)
declare -a MRF_EPSGS=(EPSG3413 EPSG3031)
for INDEX in {0..1}
do
	sudo mkdir -p /usr/share/onearth/demo/data/${MRF_EPSGS[$INDEX]}/blue_marble2004336
	sudo cp /vagrant/mrfs/blue_marble_${MRF_PROJS[$INDEX]}/* /usr/share/onearth/demo/data/${MRF_EPSGS[$INDEX]}/blue_marble2004336/
	sudo cp /vagrant/mrfs/blue_marble_${MRF_PROJS[$INDEX]}/blue_marble2004336_.mrf /etc/onearth/config/headers/blue_marble2004336_${MRF_PROJS[$INDEX]}.mrf
done

#Copy layer config files, run config tool, restart Apache. For some reason LCDIR needs to be attached during initial provision
sudo cp /vagrant/layer_configs/* /etc/onearth/config/layers/
sudo LCDIR=/junk/etc/onearth/config oe_configure_layer --layer_dir=/etc/onearth/config/layers/ -r

clear
echo "OnEarth server is now live at http://localhost:8080."