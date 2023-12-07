#!/bin/bash

# Konfigurasi MySQL
db_host="10.10.92.102"
db_user="server"
db_password="1234"
db_name="ppid_polinema"
db_table_keywords="ppid_security_keywords"
db_table_cronjob="ppid_security_cronjob"

# Tentukan direktori yang akan dijelajahi
directory="/nfs-share/ppid"
quarantine_directory="/path/to/quarantine"  # Gantilah dengan direktori tempat Anda ingin menyimpan file yang di-karantina

# Koneksi ke MySQL dan ambil kata-kata dari tabel
keywords=($(mysql -h "$db_host" -u "$db_user" -p"$db_password" -D "$db_name" -se "SELECT keyword FROM $db_table_keywords"))

# Tentukan nama file log
log_file="log.txt"

# Cek apakah file log sudah ada, jika belum, buat file baru
if [ ! -e "$log_file" ]; then
    touch "$log_file"
fi

# Tambahkan tanggal eksekusi ke dalam file log
echo "Tanggal eksekusi: $(date)" >> "$log_file"

# Loop melalui setiap kata kunci yang dicari
for keyword in "${keywords[@]}"; do
    # Temukan file yang berisi kata kunci dan lakukan validasi sebelum menyimpan ke tabel MySQL
    find "$directory" -type f -exec grep -q "$keyword" {} \; -exec sh -c '
        file_path="{}"
        modified_date=$(stat -c %y "$file_path")
        if ! mysql -h "$0" -u "$1" -p"$2" -D "$3" -se "SELECT * FROM ppid_security_cronjob WHERE keyword = \"$5\" AND path = \"$file_path\" AND status = 0 LIMIT 1;" | grep -q "1"; then
            # Pindahkan file ke direktori karantina dan ubah ekstensinya
            quarantine_file="$quarantine_directory/$(basename "$file_path").fbag"
            mv "$file_path" "$quarantine_file"
            
            # Insert informasi ke dalam tabel MySQL, termasuk jalur karantina yang sudah digabungkan
            echo "$(date): Data dengan kata kunci \"$5\" berhasil disimpan dan file dipindahkan ke karantina." >> "$6"
            mysql -h "$0" -u "$1" -p"$2" -D "$3" -e "INSERT INTO $7 (keyword, tgl_waktu, path, modified_date, quarantine) VALUES (\"$5\", NOW(), \"$file_path\", \"$modified_date\", \"$quarantine_directory/$quarantine_file\")";
        else
            echo "$(date): Data dengan kata kunci \"$5\" sudah ada dalam tabel." >> "$6";
        fi
    ' "$db_host" "$db_user" "$db_password" "$db_name" "$db_table_keywords" "$keyword" "$log_file" "$db_table_cronjob" \;
done

echo "Proses selesai."

