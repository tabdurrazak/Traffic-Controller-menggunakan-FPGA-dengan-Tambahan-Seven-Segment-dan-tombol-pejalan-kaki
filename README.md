# Laporan Tugas Besar  
### Kuliah Desain FPGA dan SoC  

**Kelompok** :  
**Nama–NIM Anggota 1** : Tengku Abdurrazak Johan-1102223123
**Nama–NIM Anggota 2** : Nabil Al-Faiq Rinovka-1102223150
**Nama–NIM Anggota 3** : Nazer Muhammad Noor-1102223120

---

# Judul  
**Traffic Controller menggunakan FPGA dengan Tambahan Seven Segment dan tombol pejalan kaki**
---

# Deskripsi 
Tugas besar ini berfokus pada perancangan dan implementasi Traffic Light Controller berbasis FPGA sebagai representasi sistem kendali digital pada persimpangan jalan. Sistem dirancang untuk mengatur durasi lampu lalu lintas merah(LED1), kuning(LED2), dan hijau(LED3) secara otomatis menggunakan logika sekuensial yang diimplementasikan dalam FPGA serta menambahkan fitur seven segment dan tombol pejalan kaki.
Pengendalian lampu dilakukan melalui finite state machine (FSM), di mana setiap kondisi lampu direpresentasikan sebagai state yang berbeda dan berpindah berdasarkan sinyal clock internal. Untuk meningkatkan aspek informatif sistem, ditambahkan tampilan 7-segment yang berfungsi menampilkan hitung mundur waktu atau status fase lampu lalu lintas.

---

# Fungsi 
- Mengendalikan urutan lampu lalu lintas merah, kuning, hijau secara otomatis.
- Mengimplementasikan finite state machine (FSM) pada FPGA untuk perpindahan fase lampu.
- Mengatur durasi tiap lampu menggunakan clock dan counter internal FPGA.
- Menampilkan status atau hitung mundur fase lampu melalui 7-segment display.
- Memeberikan fungsi opsional untuk pejalan kaki yang ingin menyebrang jalan.


---

# Fitur dan Spesifikasi  

## **Fitur**
- Traffic Controller berbasis FPGA	untuk Mengatur nyala LED merah, kuning, dan hijau secara otomatis
- Tombol Pejalan Kaki	untuk Mengatur lampu untuk pejalan kaki menyebrang jalan
- Seven Segment	untuk Menampilkan status atau hitung mundur fase lampu pada 7 segment display.


## **Spesifikasi**
Spesifikasi:
- Sistem diimplementasikan menggunakan FPGA sebagai pengendali utama
- Logika kendali menggunakan Finite State Machine (FSM)
- Output berupa LED merah, kuning, dan hijau
- Tampilan tambahan menggunakan 7-segment display
- Waktu tiap fase lampu ditentukan oleh clock internal FPGA
- Tombol untuk pejalan kaki menyebrang jalan


---

# Cara Penggunaan  
Cara Penggunaan Sistem Traffic Controller FPGA 
- Sistem diaktifkan dengan memberikan catu daya pada FPGA. 
- FPGA melakukan inisialisasi sistem dan masuk ke state awal (lampu merah menyala). 
- Clock internal mulai menghitung waktu untuk setiap fase lampu. 
- LED hijau menyala sesuai durasi yang telah ditentukan. 
- Setelah waktu hijau habis, sistem berpindah ke lampu kuning sebagai fase transisi. 
- Sistem kemudian berpindah ke lampu merah untuk menghentikan arus lalu lintas. 
- 7-segment display menampilkan status atau sisa waktu fase lampu aktif.
- Jika tombol pejalan kaki ditekan, maka lampu akan berubah menjadi merah selama detik yang tentukan.
- Proses berulang secara kontinu selama sistem diberi catu daya.


# Blok Diagram  
// ini contoh 
<img width="629" height="250" alt="image" src="https://github.com/tabdurrazak/Traffic-Controller-menggunakan-FPGA-dengan-Tambahan-Seven-Segment-dan-tombol-pejalan-kaki/blob/main/DiagBlok%20FPGA.jpg" />

Pada Blok input, terdapat tiga elemen utama yaitu push button pejalan kaki, push button reset, dan power.  Push button pejalan kaki digunakan ketika ada seorang pejalan kaki yang ingin menyebrang. Pejalan kaki tersebut dapat menekan tombol dan lampu yang awalnya hijau akan menjadi merah sehingga pejalan kaki dapat menyebrang. Selain itu, pada push button reset berfungsi sebagai melakukan reset pada sistem jika sistem mengalami gangguan. Terakhir, Blok Power menunjukkan suplai utama untuk kebutuhan sistem, suplai dapat dialiri tegangan 5V atau 12V sesuai dengan kebutuhan pada sistem.
Pada bagian proses hanya terdapat Board Module FPGA sebagai otak utama dalam keseluruhan sistem. Board FPGA berfungsi sebagai sistem yang dapat menerima input, melakukan proses pada input tersebut, dan mengeluarkan output yang diinginkan. Dalam konteks Tugas besar ini, Bagian proses melakukan tugasnya sebagai traffic light, namun ketika ada yang menekan tombol reset atau tombol pejalan kaki, FPGA akan memproses input tersebut dan mengeluarkan output sesuai dengan masing-masing kegunaannya.
Terakhir, pada bagian Output, terdapat tiga LED utama sebagai penanda lampu lalu lintas. Terdapat Led merah kunin, dan hijau sesuai dengan standar lampu lalu lintas. LED akan menunjukkan “state” atau kondisi sesuai dengan proses yang sudah dilakukan sebelumnya. Terakhir, ada bagian seven segment dimana seven segment akan menunjukkan waktu yang tersisa dalam setiap statenya untuk memberitahu berapa lama lagi lampu akan merah atau lampu akan hijau.

---

# FSM (Mealy Machine)

Finite State Machine (FSM) pada sistem lampu lalu lintas ini terdiri dari lima state, yaitu S_GREEN, S_Y_G2R, S_RED, S_PED, dan S_Y_R2G, yang masing-masing merepresentasikan fase hijau kendaraan, kuning transisi hijau ke merah, merah kendaraan, fase penyeberangan pejalan kaki, serta kuning transisi merah ke hijau. FSM bekerja dengan pendekatan Mealy, di mana keputusan transisi state dipengaruhi oleh kondisi input berupa status timer (timer_done) dan permintaan pedestrian (ped_req), sedangkan keluaran sistem ditentukan oleh state aktif. Sistem diawali pada state S_RED setelah reset, dengan durasi waktu tiap state dikendalikan oleh penghitung waktu berbasis detik.
Pada kondisi operasi normal tanpa permintaan pedestrian, FSM mengikuti siklus S_RED → S_Y_R2G → S_GREEN → S_Y_G2R → S_RED secara berulang. Transisi antar state terjadi ketika waktu pada state aktif telah habis, yang ditandai oleh sinyal timer_done. Pada state S_GREEN dan S_RED, nilai penghitung waktu ditampilkan pada seven-segment display, sedangkan pada state kuning dan fase pedestrian tampilan dimatikan. Dengan mekanisme ini, sistem memastikan setiap fase lampu berlangsung sesuai durasi yang telah ditentukan.
Ketika tombol pedestrian ditekan, permintaan tersebut dilatch ke dalam sinyal ped_req dan diprioritaskan oleh FSM. Jika ped_req aktif saat berada di state S_GREEN, fase hijau akan dipotong dan sistem berpindah ke state S_Y_G2R, kemudian menuju S_RED. Selanjutnya, FSM memasuki state S_PED, di mana lampu kendaraan tetap merah dan indikator penyeberangan pejalan kaki aktif selama durasi tertentu. Setelah fase pedestrian selesai, FSM berpindah ke state S_Y_R2G dan kembali ke S_GREEN, sekaligus menghapus permintaan pedestrian yang telah dilayani. Dengan demikian, setiap permintaan pedestrian dipastikan diproses satu kali sebelum sistem kembali ke siklus normal.


<img width="303" height="181" alt="image" src="https://github.com/tabdurrazak/Traffic-Controller-menggunakan-FPGA-dengan-Tambahan-Seven-Segment-dan-tombol-pejalan-kaki/blob/main/statemachine.jpg" />

---
# Hasil simulasi dan Analisis

<img width="987" height="309" alt="image" src="https://github.com/tabdurrazak/Traffic-Controller-menggunakan-FPGA-dengan-Tambahan-Seven-Segment-dan-tombol-pejalan-kaki/blob/main/Screenshot%202026-01-04%20193312.png" />

Waveform menunjukkan bahwa clock dan input bekerja normal dengan reset = 0 sehingga FSM aktif. Saat input din membentuk urutan 1 → 0 → 1, FSM bergerak melalui state S0 → S1 → S2 → S1. Pada saat FSM berada di S2 dan menerima input 1, output dout menjadi HIGH selama satu siklus clock. Hal ini menandakan bahwa pola 101 berhasil terdeteksi tepat pada transisi yang sesuai dengan karakter Mealy Machine (output muncul berdasarkan state + input). Setelah deteksi, FSM kembali ke state S1 sehingga overlapping dapat dideteksi pada urutan berikutnya. Secara keseluruhan, waveform menunjukkan bahwa sequence detector Mealy 101 berjalan sesuai desain dan berfungsi dengan benar.

# Lampiran (Kode Verilog)
Kode Verilog ada di sini: [traffic_mealy.v](src/traffic_mealy.v) 
File test: [tb_traffic_mealy.v](src/tb_traffic_mealy.v) 

# Link Video Implementasi
https://drive.google.com/file/d/1gtrh9Nj3vBQcqFoFia6eptZ_oBg90y_a/view?usp=sharing

