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
        modified_date=$(stat -c %y "{}");
        if ! mysql -h "$0" -u "$1" -p"$2" -D "$3" -se "SELECT * FROM ppid_security_cronjob WHERE keyword = \"$5\" AND path = \"{}\" AND status = 0 LIMIT 1;" | grep -q "1"; then
            echo "$(date): Data dengan kata kunci \"$5\" berhasil disimpan." >> "$6";
            mysql -h "$0" -u "$1" -p"$2" -D "$3" -e "INSERT INTO $7 (keyword, tgl_waktu, path, modified_date) VALUES (\"$5\", NOW(), \"{}\", \"$modified_date\")";
        else
            echo "$(date): Data dengan kata kunci \"$5\" sudah ada dalam tabel." >> "$6";
        fi
    ' "$db_host" "$db_user" "$db_password" "$db_name" "$db_table_keywords" "$keyword" "$log_file" "$db_table_cronjob" \;
done

echo "Proses selesai."

