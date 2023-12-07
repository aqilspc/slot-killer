#!/bin/bash

# Tentukan direktori yang akan dijelajahi
directory="/path/to/directory"

# Tentukan kata-kata yang dicari (pisahkan dengan spasi)
keywords=("Togel" "" "kata3")

# Tentukan nama file log
log_file="log_file.txt"

# Cek apakah file log sudah ada, jika belum, buat file baru
if [ ! -e "$log_file" ]; then
    touch "$log_file"
fi

# Loop melalui setiap kata yang dicari
for keyword in "${keywords[@]}"; do
    # Temukan file yang berisi kata dan hapus
    find "$directory" -type f -exec grep -q "$keyword" {} \; -exec echo "File yang berisi kata '$keyword' ditemukan: {}" >> "$log_file" \; -exec rm {} \;
done

echo "Proses selesai."
