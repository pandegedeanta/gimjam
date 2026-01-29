extends Node2D

func _ready():
	# Pastikan teks sembunyi dulu saat mulai (opsional)
	$Label.visible = false
	
	# Mainkan animasi
	$AnimatedSprite2D.play("default")
	
	# Hubungkan sinyal "frame_changed" milik AnimatedSprite2D ke fungsi baru di bawah
	# Artinya: "Setiap kali frame ganti, jalankan fungsi _cek_frame"
	$AnimatedSprite2D.frame_changed.connect(_cek_frame)

func _cek_frame():
	# Ambil nomor frame saat ini
	var frame_sekarang = $AnimatedSprite2D.frame
	
	# Cek apakah frame saat ini adalah 6, 7, atau 8
	# Kita pakai array [6, 7, 8] biar lebih rapi daripada pakai banyak "or"
	if frame_sekarang in [6, 7, 8]:
		$Label.visible = true  # Munculkan teks
	else:
		$Label.visible = false # Sembunyikan teks di frame lain
