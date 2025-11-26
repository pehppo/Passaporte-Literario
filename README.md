# 📚 Passaporte Literário

Aplicativo Flutter criado para ajudar leitores a **registrar, organizar e acompanhar suas leituras** de forma simples e visual.

Com o Passaporte Literário você pode salvar livros, anotar impressões, definir metas de leitura e acompanhar estatísticas ao longo do tempo.

---

## ✨ Principais recursos

- 📖 **Cadastro de livros**
  - Adicionar livros manualmente
  - Buscar informações pela **Google Books API** (título, autor, capa, etc.)
  - Editar e remover livros

- 📝 **Diário de leitura**
  - Registrar sessões de leitura
  - Anotar impressões, sentimentos e momentos marcantes

- 🎯 **Metas e progresso**
  - Definição de metas de leitura
  - Acompanhamento de progresso
  - Estatísticas de livros lidos, páginas lidas, avaliações e metas concluídas

- ⭐ **Avaliações**
  - Avaliar livros lidos
  - Registrar notas e comentários

- 📌 **Lista de desejos**
  - Salvar livros que você quer ler futuramente
  - Facilitar organização de próximas leituras

- 👤 **Perfil do leitor**
  - Visão geral das estatísticas de leitura
  - Informações agregadas (livros lidos, metas, páginas, avaliações etc.)

---

## 🛠 Tecnologias e serviços

- **Flutter** (Dart)
- **Firebase Authentication** – login e autenticação de usuários (incluindo Google Sign-In)
- **Cloud Firestore** – armazenamento de livros, diário, metas e demais dados
- **Cloudinary** – armazenamento e gerenciamento de imagens (capas/fotos)
- **Google Books API** – busca de informações de livros
- **HTTP / REST** – integração com serviços externos
- **Image Picker** – seleção de imagens a partir do dispositivo

> Toda a parte de armazenamento local com `SharedPreferences` foi **substituída por Firebase + Cloudinary**, para garantir sincronização entre dispositivos e persistência em nuvem.

---

## 📲 Plataforma

Atualmente o foco do app é:

- ✅ **Android**

Outras plataformas podem ser avaliadas futuramente (Web / Desktop), conforme evolução do projeto.

---

## 📦 APK

A versão compilada do aplicativo (APK) está disponível na aba Releases do repositório:

---

## 🧩 Estrutura básica do projeto

```
passaporte_literario/
│
├── android/
├── assets/
│     └── images/
├── lib/
    └── services/
  ├── add_screen.dart
  ├── book_details_screen.dart
  ├── cadastro_screen.dart
  ├── diario_screen.dart
  ├── donate_screen.dart
  ├── edit_book_screen.dart
  ├── edit_profile.dart
  ├── firebase_options.dart
  ├── home_screen.dart
  ├── login_screen.dart
  ├── main.dart
  ├── metas_screen.dart
  ├── perfil_screen.dart
  ├── settings.dart
  └── wishlist_screen.dart
```
