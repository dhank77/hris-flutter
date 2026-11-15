# Perintah harian. Jalankan `make help` untuk daftar lengkap.
DEFINES := --dart-define-from-file=config/dev.json

.PHONY: help setup get gen watch format analyze test check run run-web feature skills upgrade clean

help: ## Tampilkan daftar perintah
	@grep -E '^[a-z-]+:.*## ' Makefile | awk 'BEGIN {FS = ":.*## "}; {printf "  make %-10s %s\n", $$1, $$2}'

setup: ## Setup pertama kali (platform, deps, codegen, cek)
	./scripts/setup.sh

get: ## flutter pub get
	flutter pub get

gen: ## Generate kode Freezed/JSON sekali
	dart run build_runner build --delete-conflicting-outputs

watch: ## Generate kode otomatis saat file berubah
	dart run build_runner watch --delete-conflicting-outputs

format: ## Format kode
	dart format lib test

analyze: ## Analisis statis
	flutter analyze

test: ## Jalankan semua test
	flutter test

check: format analyze test ## Format + analyze + test (wajib sebelum commit)

run: ## Jalankan app (config/dev.json)
	flutter run $(DEFINES)

run-web: ## Jalankan app di Chrome
	flutter run -d chrome $(DEFINES)

feature: ## Buat fitur baru: make feature name=posts [model=Post]
	@test -n "$(name)" || (echo "Pakai: make feature name=<nama_fitur> [model=NamaModel]"; exit 1)
	./scripts/new_feature.sh $(name) $(model)

skills: ## Pasang/perbarui skill agen resmi Flutter & Dart
	./scripts/install_skills.sh

upgrade: ## Naikkan dependensi ke versi mayor terbaru + codegen
	./scripts/bootstrap_dependencies.sh

clean: ## Bersihkan build lalu generate ulang
	flutter clean
	flutter pub get
	$(MAKE) gen
