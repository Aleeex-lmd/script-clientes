sudo apt install -y libdaq2 cmake gcc g++ flex bison libpcap-dev libssl-dev libdaq-dev libhwloc-dev libluajit-5.1-dev libjansson-dev libpcre2-dev zlib1g-dev libunwind-dev uuid-dev

git clone https://github.com/snort3/libdaq.git

cd libdaq
./bootstrap
./configure
make install

sudo ldconfig

cd /home/debian
git clone https://github.com/snort3/snort3.git

cd snort3
./configure_cmake.sh
cd build

make -j $(nproc)
make instal