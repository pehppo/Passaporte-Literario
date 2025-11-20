# Configuração do Firebase

## ⚠️ Segurança

As credenciais do Firebase **nunca devem ser commitadas** no repositório. O arquivo `lib/firebase_options.dart` está listado no `.gitignore` para proteger suas chaves.

## 📋 Como Configurar

### Opção 1: Usando arquivo local (Recomendado para desenvolvimento)

1. Copie `firebase_options.example.dart` para `lib/firebase_options.dart`:
   ```bash
   cp firebase_options.example.dart lib/firebase_options.dart
   ```

2. Edite `lib/firebase_options.dart` com suas credenciais reais:
   ```dart
   static const FirebaseOptions android = FirebaseOptions(
     apiKey: 'YOUR_ACTUAL_API_KEY',
     appId: '1:YOUR_SENDER_ID:android:YOUR_APP_ID',
     messagingSenderId: 'YOUR_SENDER_ID',
     projectId: 'your-project-id',
     storageBucket: 'your-project.firebasestorage.app',
   );
   ```

3. Execute o app normalmente:
   ```bash
   flutter run
   ```

### Opção 2: Usando variáveis de ambiente (Recomendado para CI/CD)

1. Execute com `--dart-define`:
   ```bash
   flutter run \
     --dart-define=FIREBASE_API_KEY=YOUR_API_KEY \
     --dart-define=FIREBASE_APP_ID=YOUR_APP_ID \
     --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID \
     --dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID \
     --dart-define=FIREBASE_STORAGE_BUCKET=YOUR_BUCKET
   ```

2. Para build APK:
   ```bash
   flutter build apk \
     --dart-define=FIREBASE_API_KEY=YOUR_API_KEY \
     --dart-define=FIREBASE_APP_ID=YOUR_APP_ID \
     --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID \
     --dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID \
     --dart-define=FIREBASE_STORAGE_BUCKET=YOUR_BUCKET
   ```

## 📖 Obter Credenciais do Firebase

1. Acesse [Firebase Console](https://console.firebase.google.com)
2. Selecione seu projeto
3. Vá para **Configurações do Projeto** → **Sua Apps** → **Configuração Android**
4. Copie as credenciais necessárias

## ✅ Verificação de Segurança

Antes de fazer commit, verifique:
- ✅ `lib/firebase_options.dart` NÃO está commitado
- ✅ `.gitignore` contém `lib/firebase_options.dart`
- ✅ Nenhuma chave privada aparece no histórico de commits

## 🔄 Se Acidentalmente Commitar Chaves

1. **Revoque as chaves no Firebase Console**
2. **Gere novas chaves**
3. **Atualize o arquivo local** com as novas credenciais
4. **Force push** para limpar o histórico:
   ```bash
   git push origin main --force
   ```

