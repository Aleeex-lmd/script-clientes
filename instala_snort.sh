sudo apt install -y libdaq2 cmake gcc g++ flex bison libpcap-dev libssl-dev libdaq-dev libhwloc-dev libluajit-5.1-dev libjansson-dev libpcre2-dev zlib1g-dev libunwind-dev uuid-dev libpcre3-dev build-essential libnet1-dev git -y


git clone https://github.com/snort3/libdaq.git

cd libdaq
./bootstrap
./configure --prefix=/usr/local/lib/daq_s3
sudo make install

sudo ldconfig

git clone https://github.com/snort3/snort3.git

export my_path=/usr/local/bin
mkdir -p $my_path
cd snort3
./configure_cmake.sh --prefix=$my_path \
                       --with-daq-includes=/usr/local/lib/daq_s3/include/ \
                       --with-daq-libraries=/usr/local/lib/daq_s3/lib/

cd build
make -j $(nproc)
sudo make install

alias snort='/usr/local/bin/snort/bin/snort --daq-dir /usr/local/lib/daq_s3/lib/daq'
