class Config {
  // ⚠️ PENTING: Ganti URL sesuai dengan kondisi:
  // 1. Emulator Android: http://10.0.2.2:8000/api
  // 2. HP Fisik: http://192.168.x.x:8000/api (ganti x.x dengan IP laptop kamu)
  // 3. Cek IP laptop dengan: ipconfig (Windows) atau ifconfig (Mac/Linux)
  
  // Untuk Emulator Android (10.0.2.2 = localhost dari sisi emulator)
  static const String baseUrl = 'https://notezque.kolab.top/api';
  
  // 💡 Jika pakai HP fisik, uncomment baris di bawah dan ganti dengan IP laptop:
  // static const String baseUrl = 'http://192.168.1.5:8000/api'; // Contoh
}
