# Son Yolcu

## English

**Son Yolcu** is a mobile-first, portrait Godot narrative card game set in a remote mountain hotel. Decide which guests may stay, read their stories and clues, manage rooms and scarce resources, and see the night through. The game includes eight chapters, 70 guests, multiple endings, upgrades, and original artwork.

### Languages

The game currently offers **Turkish (default)** and **Azerbaijani**. English is not a game-interface or story-content language in this version. This README is bilingual; it does not change the game.

### Play and save data

The game remains playable offline, with progress saved locally on the device. If a player chooses Manus sign-in and has a connection, the account's save can synchronize across devices. When a changed local save conflicts with the cloud copy, the game asks which copy to keep instead of silently overwriting either. Cloud sync requires the published hybrid service and an authenticated Manus session. Local play and local saves remain available without an account or network connection.

Browser storage and service-worker availability depend on the browser and device; private browsing or storage-clearing settings may remove local data. Cross-device sync requires signing into the same account and is not a replacement for keeping a device backup.

### Run locally

Open `project.godot` with **Godot 4.7** (GL Compatibility renderer), or run:

```sh
godot --path .
```

In the managed project environment, run the configured check with `npm run check`.

### Web build and backend

The web build uses Godot's Web export and the project's PWA shell. Serve the exported game over HTTPS or localhost. The managed deployment serves static game files alongside the authenticated API. The server uses platform-managed Manus authentication and a MySQL database; do not commit credentials. Schema changes are additive and repeatable through `server/migrate.mjs`. The account-owned save API validates the authenticated user on the server and uses revision checks to detect competing updates.

### Android

This repository does not include a signed Android release or a configured native wrapper. A future Android build needs the matching Godot export templates, Android SDK, JDK, and signing configuration. A separately configured web wrapper is another option.

### Project layout and current scope

`data/` contains guest, chapter, and story data; `localization/` contains interface translations; `scripts/game/son_logic.gd` implements the night and decisions; `scripts/game/son_save.gd` handles local persistence; `scripts/game/son_cloud.gd` coordinates optional account sync; and `server/` contains the authenticated API and database migrations. The DejaVu Sans Mono license is included alongside the font assets.

The first story night uses authored chapter groups; later nights reshuffle eligible guests. Some rules share underlying effects, some later-night variants are simplified, and some reports use generalized outcomes. Browser install/offline behavior and device-specific acceptance should be checked on the target device.

---

## Türkçe

**Son Yolcu**, uzak bir dağ otelinde geçen, mobil öncelikli ve dikey ekran için tasarlanmış bir Godot anlatı kart oyunudur. Otele hangi konukların gireceğine karar verin, hikâyeleri ve ipuçlarını okuyun, odaları ve kısıtlı kaynakları yönetin ve geceyi atlatmaya çalışın. Oyunda sekiz bölüm, 70 konuk, birden fazla son, geliştirmeler ve özgün çizimler bulunur.

### Diller

Oyun şu anda **Türkçe (varsayılan)** ve **Azerbaycanca** sunar. Bu sürümde oyun arayüzü ve hikâye metinleri İngilizce değildir. Bu README iki dillidir; oyunun kendisini değiştirmez.

### Oynama ve kayıt verileri

Oyun çevrimdışı oynanabilir; ilerleme cihazda yerel olarak kaydedilir. Oyuncu Manus ile oturum açar ve internet bağlantısı bulunursa, hesabına ait kayıt cihazlar arasında eşitlenebilir. Değiştirilmiş yerel kayıt buluttaki kayıtla çakışırsa oyun, hiçbirini sessizce ezmeden hangi kopyanın kullanılacağını sorar. Bulut eşitlemesi, yayımlanmış hibrit hizmet ve doğrulanmış Manus oturumu gerektirir. Hesap veya bağlantı olmadığında yerel oyun ve kayıt kullanılabilir.

Tarayıcı depolama alanı ve service worker desteği tarayıcıya ve cihaza bağlıdır; gizli gezinme veya depolama temizleme ayarları yerel verileri silebilir. Cihazlar arası eşitleme için aynı hesapla oturum açılmalıdır ve cihaz yedeğinin yerine geçmez.

### Yerel çalıştırma

`project.godot` dosyasını **Godot 4.7** ile açın (GL Compatibility renderer) veya şu komutu çalıştırın:

```sh
godot --path .
```

Yönetilen proje ortamındaki yapılandırılmış kontrolü `npm run check` ile çalıştırın.

### Web sürümü ve sunucu

Web sürümü Godot Web dışa aktarımını ve projeye ait PWA kabuğunu kullanır. Dışa aktarılan oyunu HTTPS veya localhost üzerinden sunun. Yönetilen dağıtım, statik oyun dosyalarını kimlik doğrulamalı API ile birlikte sunar. Sunucu, platformun yönettiği Manus kimlik doğrulamasını ve MySQL veritabanını kullanır; kimlik bilgilerini depoya eklemeyin. Şema değişiklikleri `server/migrate.mjs` aracılığıyla eklemeli ve tekrarlanabilir biçimde uygulanır. Hesaba bağlı kayıt API'si oturum açmış kullanıcıyı sunucuda doğrular ve eşzamanlı güncellemeleri saptamak için revizyon denetimi kullanır.

### Android

Bu depoda imzalanmış Android sürümü veya yapılandırılmış yerel uygulama kabuğu bulunmaz. İleride Android derlemesi için uyumlu Godot dışa aktarım şablonları, Android SDK, JDK ve imzalama yapılandırması gerekir. Ayrı olarak yapılandırılmış bir web uygulama kabuğu da kullanılabilir.

### Proje yapısı ve mevcut kapsam

`data/` konuk, bölüm ve hikâye verilerini; `localization/` arayüz çevirilerini; `scripts/game/son_logic.gd` gece akışını ve kararları; `scripts/game/son_save.gd` yerel kayıtları; `scripts/game/son_cloud.gd` isteğe bağlı hesap eşitlemesini; `server/` ise kimlik doğrulamalı API ile veritabanı geçişlerini içerir. DejaVu Sans Mono lisansı yazı tipi dosyalarının yanında bulunur.

İlk hikâye gecesi yazılmış bölüm gruplarını kullanır; sonraki gecelerde uygun konuklar yeniden sıralanır. Bazı kurallar ortak etkileri kullanır, sonraki gecelerdeki bazı varyantlar sadeleştirilmiştir ve bazı raporlar genelleştirilmiş sonuçlar sunar. Tarayıcı kurulumu/çevrimdışı çalışma ve cihaza özgü kabul, hedef cihazda ayrıca kontrol edilmelidir.
